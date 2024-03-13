module publisher::aptos_horses
{
    use aptos_token_objects::token;
    use aptos_framework::object;
    use std::option::{Self, Option};
    use std::vector;
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::randomness;
    use aptos_token_objects::collection;
    use aptos_std::string_utils;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use publisher::aptos_horses_publisher_signer;

    struct Collection has key 
    {
        soulbound: bool,
        mintable: bool,
        one_to_one_mapping: Option<SmartTable<address, address>>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Horses has key
    {
        horses: vector<Horse>
    }

    struct Horse has store, copy, drop, key
    {
        id: u64,
        name: String,
        description: String,
        uri: String,
        price: u64,
        speed: u64
    }

    fun init_module(admin: &signer) 
    {
        let horses: vector<Horse> = 
        vector<Horse>[
            Horse
            {
                id: 0,
                name: string::utf8(b"Midnight Star"),
                description: string::utf8(b"Ride the fastest horse in the west through treacherous terrain and wild weather"),
                price: 4 * 100000000,
                uri: string::utf8(b"https://bafkreiewuq5pbrecvq7z7kohdoxyo66p7n3nc2hnilxiiwe3okz3tpkpwi.ipfs.nftstorage.link/"),
                speed: 0
            },
            Horse
            {
                id: 1,
                name: string::utf8(b"Golden Blaze"),
                description: string::utf8(b"Explore mystical lands under the cloak of night on this mysterious and elegant horse"),
                price: 6 * 100000000,
                uri: string::utf8(b"https://bafkreib7ndr2kd52qvhgukpdihuel6yi222pmn43gr3ffignyx52iqzw7q.ipfs.nftstorage.link/"),
                speed: 0
            },
            Horse
            {
                id: 2,
                name: string::utf8(b"Silver Moon"),
                description: string::utf8(b"Embark on a quest for gold and glory with this majestic and noble steed"),
                price: 8 * 100000000,
                uri: string::utf8(b"https://bafkreicb3ebvgbazgqqfillv6p2kdktgw5fgkrvzqam23eyxvimlmlxuge.ipfs.nftstorage.link/"),
                speed: 0
            },
            Horse
            {
                id: 3,
                name: string::utf8(b"Stormy Lightening"),
                description: string::utf8(b"Journey through enchanted forests and mystical realms under the silver light of the moon"),
                price: 10 * 100000000,
                uri: string::utf8(b"https://bafkreidww2qkvocxuhnumbsvxl2v4kbgej62bsh5tw355eb2lcgqvyf6xe.ipfs.nftstorage.link/"),
                speed: 0
            },
        ];

        move_to(admin, Horses { horses });
    }

    #[view]
    public fun get_all_metadata(): vector<Horse> acquires Horses
    {
        let horses = borrow_global<Horses>(@publisher).horses;
        horses
    }

    public fun create_collection(creator: &signer) 
    {
        let constructor_ref = collection::create_unlimited_collection(
            creator,
            string::utf8(b"The fastest horses on Aptos!"),
            string::utf8(b"APTHorse"),
            option::none(),
            string::utf8(b"https://linktr.ee/intotheverse")
        );

        move_to(&object::generate_signer(&constructor_ref), Collection {
            soulbound: false,
            mintable: true,
            one_to_one_mapping: option::some(smart_table::new())
        });
    }

    public entry fun mint_horse(creator: &signer, horse_id: u64) acquires Horses
    {
        let horses = &mut borrow_global_mut<Horses>(@publisher).horses;
        let horse = vector::borrow_mut(horses, horse_id);

        horse.speed = randomness::u64_range(5, get_max_speed_of_type(horse_id));

        let constructor_ref = token::create_named_token(
            creator,
            string::utf8(b"APTHorse"),
            horse.description,
            horse.name,
            option::none(),
            string_utils::format2(&b"{},{}", horse.uri, horse.price)
        );

        let token_signer = object::generate_signer(&constructor_ref);
        move_to(&token_signer, *horse);

        coin::transfer<AptosCoin>(creator, signer::address_of(&aptos_horses_publisher_signer::get_signer()), horse.price);
    }

    fun get_max_speed_of_type(type: u64): u64
    {
        let max: u64 = if(type == 0) 10 else if (type == 1) 13 else if(type == 2) 16 else if(type == 3) 19 else 0;
        max
    }
}