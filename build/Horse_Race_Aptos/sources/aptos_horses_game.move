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

    const CMaxRaceJoinCapacity: u64 = 5;

    struct Race has store, copy, drop, key
    {
        race_id: u64,
        name: String,
        price: u64,
        laps: u64,
        bet_amount: u64,
        started: bool,
        players: vector<address>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Races has key
    {
        races: vector<Race>
    }

    fun init_module(admin: &signer) 
    {
        let races: vector<Race> = 
        vector<Race>[
            Race
            {
                race_id: 0,
                name: string::utf8(b"1 Lap"),
                price: 10 * 100000000,
                laps: 1,
                bet_amount: 50 * 100000000,
                started: false,
                players: vector::empty<address>()
            },
            Race
            {
                race_id: 1,
                name: string::utf8(b"3 Laps"),
                price: 7 * 100000000,
                laps: 3,
                bet_amount: 35 * 100000000,
                started: false,
                players: vector::empty<address>()
            },
            Race
            {
                race_id: 2,
                name: string::utf8(b"5 Laps"),
                price: 4 * 100000000,
                laps: 5,
                bet_amount: 20 * 100000000,
                started: false,
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

    public entry fun join_race(user: &signer, race_id: u64) acquires Races
    {
        assert!(race_id < 3, EInvalidRaceId);

        let signer_pub_key = signer::address_of(user);
        let races = &mut borrow_global_mut<Races>(@publisher).races;
        let race = vector::borrow_mut(races, race_id);

        assert!(!vector::contains<address>(&race.players, &signer_pub_key), EUserAlreadyInRace);
        assert!(vector::length<address>(&race.players) < CMaxRaceJoinCapacity, ERaceFull);
        vector::push_back<address>(&mut race.players, signer_pub_key);

        coin::transfer<AptosCoin>(user, signer::address_of(&aptos_horses_publisher_signer::get_signer()), race.price);
    }

    #[view]
    public fun can_start_race(account_address: address, race_id: u64): (bool, u64, vector<u64>, vector<vector<u64>>) acquires Races
    {
        let races = &mut borrow_global_mut<Races>(@publisher).races;
        let race = vector::borrow_mut(races, race_id);
        if(!race.started && vector::contains<address>(&race.players, &account_address) && vector::length<address>(&race.players) == CMaxRaceJoinCapacity) 
        {
            let random_acc: vector<u64> = vector::empty<u64>();
            for (j in 0..vector::length<address>(&race.players))
            {
                vector::push_back<u64>(&mut random_acc, randomness::u64_range(25, 190));
            };

            let random_hurdles_players: vector<vector<u64>> = vector::empty<vector<u64>>();
            for (j in 0..vector::length<address>(&race.players))
            {
                let random_hurdles: vector<u64> = vector::empty<u64>();
                for (k in 0..race.laps)
                {
                    vector::push_back<u64>(&mut random_hurdles, randomness::u64_range(20, 80));
                };
                vector::push_back<vector<u64>>(&mut random_hurdles_players, random_hurdles);
            };

            race.started = true;
            return (true, race.race_id, random_acc, random_hurdles_players)
        };

        (false, 0, vector::empty<u64>(), vector::empty<vector<u64>>())
    }

    public entry fun on_race_end(race_id: u64, winning_order: vector<address>) acquires Races
    {
        let races = &mut borrow_global_mut<Races>(@publisher).races;
        let race = vector::borrow_mut(races, race_id);
        for (j in 0..vector::length<address>(&winning_order))
        {
            let receiveable_amount = randomness::u64_range(get_min_reward_by_winning_order(j), get_mix_reward_by_winning_order(j));
            coin::transfer<AptosCoin>(&aptos_horses_publisher_signer::get_signer(), *vector::borrow(&winning_order, j), receiveable_amount);
        };
        race.players = vector::empty<address>();
        race.started = false;
    }

    fun get_min_reward_by_winning_order(j: u64): u64
    {
        if (j == 0) 30 else if (j == 1) 15 else if (j == 2) 10 else if (j == 3) 5 else 3
    }

    fun get_mix_reward_by_winning_order(j: u64): u64
    {
        if (j == 0) 40 else if (j == 1) 25 else if (j == 2) 15 else if (j == 3) 10 else 7
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