address FungibleTokenAddress {
    module fungible_token {
        use aptos_framework::coin;
        use std::signer;
        use std::string;
        use std::option;

        struct Token has key {}

        struct CoinCapabilities<phantom Token> has key {
            mint_capability: coin::MintCapability<Token>,
            burn_capability: coin::BurnCapability<Token>,
            freeze_capability: coin::FreezeCapability<Token>,
        }

        const E_NO_ADMIN: u64 = 0;
        const E_NO_CAPABILITIES: u64 = 1;
        const E_HAS_CAPABILITIES: u64 = 2;

        public entry fun name(): string::String {
            return coin::name<Token>()
        }

        public entry fun symbol(): string::String {
            return coin::symbol<Token>()
        }

        public entry fun decimals(): u8 {
            return coin::decimals<Token>()
        }

        public entry fun balance(account: address): u64{
            return coin::balance<Token>(account)
        }

        public entry fun supply(): u128 {
            let supply_option: option::Option<u128> = coin::supply<Token>();
            let supply: u128 = *option::borrow(&supply_option);
            return supply
        }

        public entry fun initialize(admin: &signer) {
            let (burn_capability, freeze_capability, mint_capability) = coin::initialize<Token>(
                admin,
                string::utf8(b"Fungible Token"),
                string::utf8(b"FT"),
                6,
                true,
            );
            assert!(signer::address_of(admin) == @FungibleTokenAddress, E_NO_ADMIN);
            assert!(!exists<CoinCapabilities<Token>>(@FungibleTokenAddress), E_HAS_CAPABILITIES);
            move_to<CoinCapabilities<Token>>(
                admin, 
                CoinCapabilities<Token>{
                    mint_capability, 
                    burn_capability, 
                    freeze_capability
                }
            );
            coin::register<Token>(admin);
        }

        public entry fun register(account: &signer) {
            coin::register<Token>(account);
        }

        public entry fun transfer(from: &signer, to: address, amount: u64) {
            coin::transfer<Token>(from, to, amount);
        }

        public entry fun mint(account: &signer, to: address, amount: u64) acquires CoinCapabilities {
            let account_address = signer::address_of(account);
            assert!(account_address == @FungibleTokenAddress, E_NO_ADMIN);
            assert!(exists<CoinCapabilities<Token>>(account_address), E_NO_CAPABILITIES);
            let mint_capability = &borrow_global<CoinCapabilities<Token>>(@FungibleTokenAddress).mint_capability;
            let coins = coin::mint<Token>(amount, mint_capability);
            coin::deposit(to, coins)
        }

        public entry fun burn(account: &signer, amount: u64) acquires CoinCapabilities {
            let account_address = signer::address_of(account);
            let burn_cap = &borrow_global<CoinCapabilities<Token>>(@FungibleTokenAddress).burn_capability;
            coin::burn_from<Token>(account_address, amount, burn_cap);
        }
        
        #[test_only]
        use aptos_framework::genesis;
        #[test_only]
        use aptos_framework::account;
        #[test_only]
        use aptos_std::debug;

        #[test(
            fungible_token_account=@FungibleTokenAddress,
            some_account=@0xa11ce
            )]
        fun test_mint_transfer_burn(fungible_token_account: &signer, some_account: &signer) acquires CoinCapabilities {
            genesis::setup();
            let fungible_token_address: address = signer::address_of(fungible_token_account);
            let some_address: address = signer::address_of(some_account);
            account::create_account_for_test(fungible_token_address);
            account::create_account_for_test(some_address);

            // test mint

            initialize(fungible_token_account);
            let staking_balance_before: u64 = balance(fungible_token_address);
            debug::print<u64>(&staking_balance_before);
            let amount_to_mint = 6000000; // 6 FT
            mint(fungible_token_account, fungible_token_address, amount_to_mint);
            let staking_balance_after: u64 = balance(fungible_token_address);
            debug::print<u64>(&staking_balance_after);
            assert!(staking_balance_after == amount_to_mint, 31231);

            // test transfer

            let amount_to_transfer = amount_to_mint - 1000000;
            register(some_account);
            
            let balance_some_before_transfer: u64 = balance(some_address);
            debug::print<u64>(&balance_some_before_transfer);
            transfer(fungible_token_account, some_address, amount_to_transfer);
            let balance_some_after_transfer: u64 = balance(some_address);
            debug::print<u64>(&balance_some_after_transfer);
            assert!(balance_some_after_transfer == amount_to_transfer, 1239183);

            // test burn

            let balance_some_before_burn: u64 = balance(some_address);
            debug::print<u64>(&balance_some_before_burn);
            burn(some_account, balance_some_before_burn);
            let balance_some_after_burn: u64 = balance(some_address);
            debug::print<u64>(&balance_some_after_burn);
            assert!( balance_some_after_burn == 0, 1238781);

        }
    }
}