address MyNFTAddress {
    module my_nft {

        use std::signer;
        use std::bcs;
        use std::string::{Self, String};
        use std::option::{Self, Option};
        use aptos_token::token::{Self, TokenDataId, TokenId }; // import NFT core functions
       
        const NO_OWNER: u64 = 0;
        
        struct MyNFT has key {
            collection_name: String,
            token_name: String,
        }

        public entry fun initialize(account: &signer) {
            let account_address = signer::address_of(account);
            assert!(account_address == @MyNFTAddress, NO_OWNER);
            let collection_name: String = string::utf8(b"MyNFTCollection");
            let collection_description: String = string::utf8(b"adsba");
            let collection_uri: String = string::utf8(b"https://localhost:5000");
            let collection_maximum: u64 = 1u64;
            let mutate_setting: vector<bool> = vector<bool>[false, false, false, false, false];
           
            token::create_collection_script(
                account,
                collection_name,
                collection_description,
                collection_uri,
                collection_maximum,
                mutate_setting
            );
           
            let token_name: String = string::utf8(b"Token Name");
            let token_description: String = string::utf8(b"Token Description");
            let balance: u64 = 1u64;
            let maximum: u64 = 5u64;
            let token_uri: String = string::utf8(b"https://localhost:5001");
            let royalty_payee_address: address = @MyNFTAddress;
            let royalty_points_denominator: u64 = 100u64;
            let royalty_points_numerator: u64 = 1u64;
            let mutate_setting: vector<bool> = mutate_setting;
            let property_keys: vector<String> = vector<String>[string::utf8(b"attack"), string::utf8(b"num_of_use")];
            let property_values: vector<vector<u8>> = vector<vector<u8>>[bcs::to_bytes<u64>(&10), bcs::to_bytes<u64>(&5)];
            let property_types: vector<String> = vector<String>[string::utf8(b"u64"), string::utf8(b"u64")];
            token::create_token_script(
                account,
                collection_name,
                token_name,
                token_description,
                balance,
                maximum,
                token_uri,
                royalty_payee_address,
                royalty_points_denominator,
                royalty_points_numerator,
                mutate_setting,
                property_keys,
                property_values,
                property_types
            );
            move_to(account, MyNFT {
                collection_name: collection_name,
                token_name: token_name,
            });
        }

        public entry fun register(account: &signer) {
            //token::initialize_token_store(account);
            token::opt_in_direct_transfer(account, true);
        }

        public entry fun mint(account: &signer) acquires MyNFT {
            let my_nft = borrow_global<MyNFT>(@MyNFTAddress);
            let collection_name = my_nft.collection_name;
            let token_name = my_nft.token_name;
            let token_data_id: TokenDataId  = token::create_token_data_id(
                @MyNFTAddress,
                collection_name,
                token_name
            );
            let token_id = token::mint_token(
                account,
                token_data_id,
                1
            );
            token_id;
        }

        public entry fun transfer(account: &signer, recipient: address) acquires MyNFT {
            let from: &signer = account;
            let id: TokenId = token_id();
            let to: address = recipient;
            let amount: u64 = 1;
            token::transfer(
                from,
                id,
                to,
                amount
            );
        }

        public entry fun token_data_id(): TokenDataId acquires MyNFT {
            let creator: address = @MyNFTAddress;
            let collection: String = collection_name();
            let name: String = token_name();
            token::create_token_data_id(
                creator, 
                collection, 
                name
            )
        }

        public entry fun token_id(): TokenId acquires MyNFT {
            let creator: address = @MyNFTAddress;
            let collection: String = collection_name();
            let name: String = token_name();
            let property_version: u64 = 0;
            token::create_token_id_raw(
                creator,
                collection,
                name,
                property_version
            )
        }

        public entry fun balance_of(owner: address): u64 acquires MyNFT {
            let my_nft = borrow_global<MyNFT>(@MyNFTAddress);
            let tokenId = token::create_token_id_raw(
                @MyNFTAddress,
                my_nft.collection_name,
                my_nft.token_name,
                0
            );
            return token::balance_of(owner, tokenId)
        }



     

        public entry fun collection_supply(): u64 acquires MyNFT {
            let creator_address: address = @MyNFTAddress;
            let collection_name = borrow_global<MyNFT>(creator_address).collection_name;
            let supply_option: Option<u64> = token::get_collection_supply(creator_address, collection_name);
            let supply: u64 = *option::borrow<u64>(&supply_option);
            return supply
        }

        public entry fun collection_maximum(): u64 acquires MyNFT {
            let creator_address: address = @MyNFTAddress;
            let collection_name = borrow_global<MyNFT>(creator_address).collection_name;
            return token::get_collection_maximum(creator_address, collection_name)
        }

        public entry fun collection_name(): String acquires MyNFT{
            let my_nft = borrow_global<MyNFT>(@MyNFTAddress);
            return my_nft.collection_name
        }

        public entry fun collection_description(): String acquires MyNFT {
            let creator_address: address = @MyNFTAddress;
            let collection_name = borrow_global<MyNFT>(creator_address).collection_name;
            return token::get_collection_description(creator_address, collection_name)
        }

        public entry fun collection_uri(): String acquires MyNFT {
            let creator_address: address = @MyNFTAddress;
            let collection_name = borrow_global<MyNFT>(creator_address).collection_name;
            return token::get_collection_uri(creator_address, collection_name)
        }
        
        public entry fun token_name(): String acquires MyNFT {
            let my_nft = borrow_global<MyNFT>(@MyNFTAddress);
            return my_nft.token_name
        }



        #[test_only]
        use aptos_framework::genesis;
        #[test_only]
        use aptos_std::debug;
        #[test_only]
        use aptos_framework::account::create_account_for_test;

        #[test(
            my_nft_account=@MyNFTAddress, 
            some_account=@0xa11ce
            )]
        fun init_module_test(
            my_nft_account: &signer,
            some_account: &signer
        ) acquires MyNFT {
            genesis::setup();
            let my_nft_address: address = signer::address_of(my_nft_account);
            let some_address: address = signer::address_of(some_account);
            create_account_for_test(my_nft_address);
            create_account_for_test(some_address);
            debug::print<address>(&my_nft_address);

            initialize(my_nft_account);
            let supply = collection_supply();
            debug::print<u64>(&supply);
            let max = collection_maximum();
            debug::print<u64>(&max);
            let name = collection_name();
            debug::print<String>(&name);
            let description = collection_description();
            debug::print<String>(&description);
            let uri = collection_uri();
            debug::print<String>(&uri);

            debug::print<u64>(&balance_of(my_nft_address));
            mint(my_nft_account);
            debug::print<u64>(&balance_of(my_nft_address));
            mint(my_nft_account);
            debug::print<u64>(&balance_of(my_nft_address));

            register(some_account);            
            transfer(my_nft_account, some_address);
            debug::print<u64>(&balance_of(my_nft_address));

        
        }

    }
}