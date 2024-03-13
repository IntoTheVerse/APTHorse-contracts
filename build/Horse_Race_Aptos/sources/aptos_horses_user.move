module publisher::aptos_horses_user
{
    use std::signer;
    use std::string::{String};
    use publisher::aptos_horses;

    const EUserAlreadyExists: u64 = 0;
    const EUserDoesNotExist: u64 = 1;

    struct User has key, copy
    {
        username: String,
        equipped_horse: u64
    }
 
    public entry fun create_user(account: signer, username: String)
    {
        assert!(!exists<User>(signer::address_of(&account)), EUserAlreadyExists);

        let equipped_horse: u64 = 1000;
        move_to(&account, User {
            username,
            equipped_horse
        });
        aptos_horses::create_collection(&account);
    }

    public entry fun equip_horse(account: &signer, horse_id: u64) acquires User
    {
        let account_address = signer::address_of(account);
        assert!(exists<User>(account_address), EUserDoesNotExist);
        let user = borrow_global_mut<User>(account_address);

        user.equipped_horse = horse_id;
    }

    #[view]
    public fun get_equiped_horse(account_address: address): u64 acquires User
    {
        assert!(exists<User>(account_address), EUserDoesNotExist);
        let user = borrow_global_mut<User>(account_address);

        user.equipped_horse
    }

    public entry fun change_username(account: signer, username: String) acquires User
    {
        let account_address = signer::address_of(&account);
        assert!(exists<User>(account_address), EUserDoesNotExist);

        let user = borrow_global_mut<User>(account_address);
        user.username = username;
    }

    #[view]
    public fun get_username(account_address: address): String  acquires User
    {
        assert!(exists<User>(account_address), EUserDoesNotExist);

        let user = borrow_global<User>(account_address);
        user.username
    }
}