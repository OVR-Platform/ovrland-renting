<img src="Logo.png" style="width: 100%; height: auto;" />

# OVRLand Renting Contracts

Run following commands:

```
nvm use
```

```
npm install
```

Create `.env` file

```env
PRIVATE_KEY=""
ALCHEMY_KEY="" # POLYGON mainnet
COINMARKETCAP_API_KEY=""
```

```
npx hardhat test
```

---

Two contracts will exist: `OVRLandExperience` and `OVRLandRenting`.

The first one deals with:

- Keeping track of the URIs of the experiences which will be of 2 types:
  - **URI of the owner**, visible when a rental is not active (this experience could look like a billboard inviting users to rent).
  - **URI of the renter**, visible only within the rental period.
- Keep track of rental periods: in fact OVRLandRenting will have to communicate start timestamp and duration in months. In this way to the call of experienceURI(OVRLandAddress, nftId), the function will respond with the correct type of URI based on the presence or absence of the rent.

OVRLandRenting deals with managing the offers made by renters. Each offer has a maximum duration of 24 hours, within this time frame it is possible to overbid other offers, which if considered better will rewrite the previous one (with relative refund of the previous offerer).

- Offers longer than 1 month can only be confirmed by the owner after 24 hours.
- Offers with duration equal to 1 month, can be confirmed by the owner after 24 hours, or by the renter after 3 days. The offer expires 8 days after creation, and it is possible to place other rent offers.

Once the renting period has been started, it is not possible to make other offers.

The renter will be able to update the experience as many times as he wants (imagine if the experience doesn't work properly, it must be always possible to change it).

## Features

1. Offer creation (renter)
2. Offer acceptance (owner/renter)
3. Offer cancel (renter/renter)
4. Renting disabling (owner)
5. Experience Update (renter)
6. NoRent, renting conditions (ex. min amount per month, min and max duration).

---

## 📝 ETHERSCAN VERIFICATION

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
