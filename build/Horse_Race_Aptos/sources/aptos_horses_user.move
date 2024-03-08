module publisher::aptos_horses_user
{
    use std::signer;
    use std::string::{String};
    use publisher::aptos_horses;
    use std::option::{Self, Option};

    const EUserAlreadyExists: u64 = 0;
    const EUserDoesNotExist: u64 = 1;

    struct User has key
    {
        username: String,
        bought_horses: Option<vector<aptos_horses::Horse>>,
        equipped_horse: Option<aptos_horses::Horse>
    }
 
    public entry fun create_user(account: signer, username: String)
    {
        assert!(!exists<User>(signer::address_of(&account)), EUserAlreadyExists);

        let equipped_horse: Option<aptos_horses::Horse> = option::none();
        let bought_horses: Option<vector<aptos_horses::Horse>> = option::none();
        move_to(&account, User {
            username,
            bought_horses,
            equipped_horse
        });
        aptos_horses::create_collection(&account);
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