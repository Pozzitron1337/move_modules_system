# Stake System

## fungible token commands

init project
```
aptos move init --name FungibleToken --package-dir FungibleToken
```

init aptos accounts
```
cd FungibleToken
aptos init 
cd ..
```

compile 
```
aptos move compile --package-dir FungibleToken
```

test
```
apos move test --package-dir FungibleToken
```

## staking 

Staking is blank. The amount of FungibleToken you stake will be all withdrawn without rewards. This is template how to deposit FungibleToken to module.

init project
```
aptos move init --name Staking --package-dir Staking
```

init aptos accounts
```
cd Staking
aptos init 
cd ..
```

compile 
```
aptos move compile --package-dir Staking
```

test
```
apos move test --package-dir Staking
```

# MyNFT

Some template how to import the existing module code to your dependency. See `MyNFT/Move.toml`
Some reusage of aptos-token repo.

