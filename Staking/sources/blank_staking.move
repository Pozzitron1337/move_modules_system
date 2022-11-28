address StakingAddress {
    module blank_staking {

        use std::signer;
        use aptos_framework::coin;
        use FungibleTokenAddress::fungible_token::{Self, Token};
       

        const NO_STAKING_ACCOUNT: u64 = 0u64;
        const ERROR_UNSTAKE_MORE_THAN_EXIST_IN_POSTION: u64 = 1u64;

        struct StakingStorage has key {
            totalStake: coin::Coin<Token>
        }

        struct AccountPosition has key {
            stake: u64
        }

        public entry fun initialize(account: &signer) {
            let account_address = signer::address_of(account);
            assert!(account_address == @StakingAddress, NO_STAKING_ACCOUNT);
            let stakingStorage = StakingStorage {
                totalStake: coin::zero<Token>()
            };
            move_to(account, stakingStorage);
        }

        public entry fun register(account: &signer) {
            fungible_token::register(account)
            
        }

        public entry fun stake(account: &signer, amount: u64) acquires StakingStorage, AccountPosition {
            let account_address = signer::address_of(account);
            let coins = coin::withdraw<Token>(account, amount);
            let stakingStorage = borrow_global_mut<StakingStorage>(@StakingAddress);
            coin::merge(&mut stakingStorage.totalStake, coins);

            if(!exists<AccountPosition>(account_address)){
                move_to(account, AccountPosition {
                    stake: 0u64
                });
            };
            let userStake = borrow_global_mut<AccountPosition>(account_address);
            userStake.stake = userStake.stake + amount;

        }

        public entry fun unstake_all(account: &signer) acquires StakingStorage, AccountPosition {
            let account_address = signer::address_of(account);
            let account_position = borrow_global<AccountPosition>(account_address);
            let withdraw_amount: u64 = account_position.stake;
            unstake(account, withdraw_amount);
        }

        public entry fun unstake(account: &signer, amount: u64) acquires StakingStorage, AccountPosition {
            let account_address = signer::address_of(account);
            let account_position = borrow_global_mut<AccountPosition>(account_address);
            assert!(amount <= account_position.stake, ERROR_UNSTAKE_MORE_THAN_EXIST_IN_POSTION);
            account_position.stake = account_position.stake - amount;

            let staking_storage = borrow_global_mut<StakingStorage>(@StakingAddress);
            let coins = coin::extract<Token>(&mut staking_storage.totalStake, amount);
            coin::deposit(account_address, coins);
        }

        public entry fun userStake(account_address: address): u64 acquires AccountPosition {
            if(!exists<AccountPosition>(account_address)) {
                return 0
            } else {
                let account_position = borrow_global<AccountPosition>(account_address);
                account_position.stake
            }
        }

        public entry fun totalStake(): u64 acquires StakingStorage {
            let stakingStorage = borrow_global<StakingStorage>(@StakingAddress);
            coin::value(&stakingStorage.totalStake)
        }

        #[test_only]
        use aptos_framework::genesis;
        #[test_only]
        use aptos_std::debug;
        #[test_only]
        use aptos_framework::account::create_account_for_test;

        #[test(
            staking_account=@StakingAddress, 
            fungible_token_account=@FungibleTokenAddress,
            some_account=@0xa11ce
            )]
        fun init_module_test(
            staking_account: &signer, 
            fungible_token_account: &signer, 
            some_account: &signer
        ) acquires StakingStorage, AccountPosition{
            genesis::setup();
            let staking_address: address = signer::address_of(staking_account);
            let fungibleToken_address: address = signer::address_of(fungible_token_account);
            let some_address: address = signer::address_of(some_account);
            create_account_for_test(staking_address);
            create_account_for_test(fungibleToken_address);
            create_account_for_test(some_address);

            fungible_token::initialize(fungible_token_account);
            register(staking_account);
            let amount: u64 = 6000000;
            fungible_token::register(some_account);
            fungible_token::mint(fungible_token_account, some_address, amount);
            debug::print<u64>(&fungible_token::balance(some_address));

            initialize(staking_account);

            let amount_to_stake = amount - 1000000;
            stake(some_account, amount_to_stake);
            debug::print<u64>(&fungible_token::balance(some_address));
            debug::print<u64>(&fungible_token::balance(staking_address));
            debug::print<u64>(&totalStake());

            debug::print<u64>(&userStake(some_address));
            debug::print<u64>(&fungible_token::balance(some_address));
            unstake_all(some_account);
            debug::print<u64>(&userStake(some_address));
            debug::print<u64>(&fungible_token::balance(some_address));

        }
    }
}