module publisher::aptos_horses_publisher_signer
{
    use aptos_framework::account;
    use aptos_framework::resource_account;

    struct PermissionConfig has key 
    {
        signer_cap: account::SignerCapability,
    }

    fun init_module(account: &signer) 
    {
        let signer_cap = resource_account::retrieve_resource_account_cap(account, @publisher);
        move_to(account, PermissionConfig 
        {
            signer_cap,
        });
    }
        
    public fun get_signer(): signer acquires PermissionConfig 
    {
        let signer_cap = &borrow_global<PermissionConfig>(@publisher).signer_cap;
        account::create_signer_with_capability(signer_cap)
    }
}