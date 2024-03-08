module publisher::aptos_horses_game
{
    use std::string::{Self, String};
    use aptos_framework::randomness;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use std::vector;
    use std::signer;
    use publisher::aptos_horses_publisher_signer;

    const EInvalidRaceId: u64 = 2;
    const EUserAlreadyInRace: u64 = 3;
    const EUserNotInRace: u64 = 4;
    const ERaceFull: u64 = 5;
    const ERaceDoesntExist: u64 = 6;

    const CMaxRaceJoinCapacity: u64 = 4;

    struct Race has store, copy, drop, key
    {
        name: String,
        price: u64,
        laps: u64,
        players: vector<address>
    }

    struct OngoingRace has store, copy, drop, key
    {
        race_id: u64,
        bet_amount: u64,
        players: vector<address>,
        started: bool
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Races has key
    {
        races: vector<Race>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct OngoingRaces has key
    {
        ongoing_races: vector<OngoingRace>
    }

    fun init_module(admin: &signer) 
    {
        let races: vector<Race> = 
        vector<Race>[
            Race
            {
                name: string::utf8(b"1 Lap"),
                price: 5,
                laps: 1,
                players: vector::empty<address>()
            },
            Race
            {
                name: string::utf8(b"3 Laps"),
                price: 3,
                laps: 3,
                players: vector::empty<address>()
            },
            Race
            {
                name: string::utf8(b"5 Laps"),
                price: 1,
                laps: 5,
                players: vector::empty<address>()
            },
        ];

        move_to(admin, Races { races });
    }

    #[view]
    public fun get_all_races_metadata(): vector<Race> acquires Races
    {
        let races = borrow_global<Races>(@publisher).races;
        races
    }

    public entry fun join_race(user: &signer, race_id: u64) acquires Races, OngoingRaces
    {
        assert!(race_id < 3, EInvalidRaceId);

        let signer_pub_key = signer::address_of(user);
        let races = &mut borrow_global_mut<Races>(@publisher).races;
        let race = vector::borrow_mut(races, race_id);

        assert!(!vector::contains<address>(&race.players, &signer_pub_key), EUserAlreadyInRace);
        assert!(vector::length<address>(&race.players) < CMaxRaceJoinCapacity, ERaceFull);
        vector::push_back<address>(&mut race.players, signer_pub_key);

        coin::transfer<AptosCoin>(user, signer::address_of(&aptos_horses_publisher_signer::get_signer()), race.price);

        if(vector::length<address>(&race.players) == CMaxRaceJoinCapacity)
        {
            let ongoing_races = &mut borrow_global_mut<OngoingRaces>(@publisher).ongoing_races;
            let new_race = OngoingRace
            {
                race_id: randomness::u64_range(100, 10000000),
                bet_amount: race.price * vector::length<address>(&race.players),
                players: race.players,
                started: false
            };
            vector::push_back<OngoingRace>(ongoing_races, new_race);

            race.players = vector::empty<address>();
        }
    }

    #[view]
    public fun can_start_race(account_address: address): (bool, u64) acquires OngoingRaces
    {
        let ongoing_races = &mut borrow_global_mut<OngoingRaces>(@publisher).ongoing_races;
        for (iter in 0..vector::length<OngoingRace>(ongoing_races))
        {
            let race = vector::borrow_mut(ongoing_races, iter);
            if(!race.started && vector::contains<address>(&race.players, &account_address)) return (true, race.race_id);
        };

        (false, 0)
    }

    public entry fun start_race(race_id: u64) acquires OngoingRaces
    {
        let ongoing_races = &mut borrow_global_mut<OngoingRaces>(@publisher).ongoing_races;
        for (iter in 0..vector::length<OngoingRace>(ongoing_races))
        {
            let race = vector::borrow_mut(ongoing_races, iter);
            if(race.race_id == race_id)
            {
                race.started = true;
                break
            }
        };
    }

    public entry fun on_race_end(race_id: u64, winning_order: vector<address>) acquires OngoingRaces
    {
        let ongoing_races = &mut borrow_global_mut<OngoingRaces>(@publisher).ongoing_races;
        for (i in 0..vector::length<OngoingRace>(ongoing_races))
        {
            let race = vector::borrow_mut(ongoing_races, i);
            if(race.race_id == race_id)
            {
                for (j in 0..vector::length<address>(&winning_order))
                {
                    //Fix bet amount
                    coin::transfer<AptosCoin>(&aptos_horses_publisher_signer::get_signer(), *vector::borrow(&winning_order, j), race.bet_amount / (2 * (j + 1)));
                };
                vector::remove<OngoingRace>(ongoing_races, i);
                break
            }
        };
    }

    public entry fun leave_race(user: &signer, race_id: u64) acquires Races
    {
        assert!(race_id < 3, EInvalidRaceId);

        let signer_pub_key = signer::address_of(user);
        let races = &mut borrow_global_mut<Races>(@publisher).races;
        let race = vector::borrow_mut(races, race_id);

        let (exist, index) = vector::index_of<address>(&race.players, &signer_pub_key);
        assert!(exist, EUserNotInRace);
        vector::remove<address>(&mut race.players, index);

        coin::transfer<AptosCoin>(&aptos_horses_publisher_signer::get_signer(), signer_pub_key, race.price);
    }
}