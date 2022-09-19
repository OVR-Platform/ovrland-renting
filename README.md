<img src="Logo.png" style="width: 100%; height: auto;" />

# OVRLand Renting

Run following commands:

```
nvm use
```

```
npm install
```

Create `.env` file

```
PRIVATE_KEY=""
ALCHEMY_KEY=""
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
- Keep track of rental periods: in fact OVRLandRenting will have to communicate start timestamp and duration in months. In this way to the call of experienceURI(NFTID), the function will respond with the correct type of URI based on the presence or absence of the rent.

OVRLandRenting deals with managing the offers made by renters. Each offer has a maximum duration of 24 hours, within this time frame it is possible to make other offers, which if considered better will rewrite the previous one (with relative reimbursement of the previous offerer).

- Offers longer than 1 month can only be confirmed by the owner.
- Offers with duration equal to 1 month, can be confirmed by the owner at any time, or by the renter if for 24 hours no one has made a better offer.

Once the renting period has been started, it is not possible to make other offers.

The renter will be able to update the experience as many times as he wants (imagine if the experience doesn't work properly, it must be always possible to change it).

## Features

1. Offer creation (renter)
2. Offer acceptance (owner)
3. Offer cancel (renter)
4. Renting disabling (owner)
5. Experience Update (renter)

Offers can be made if:

- No offers have been made before
- The last offer was made less than 24 hours ago
- The last offer was made more than 7 days ago (this means that the owner is inactive, and the renter is either inactive or has made an offer for more than 1 month, if the owner is inactive offer must be redone for only 1 month)

Each time the renter makes an offer, the amount is already paid to the contract. If a new bid exceeds the previous one, the previous bidder will be refunded.

In case of acceptance, the amount paid by the bidder will be credited to the owner, while the renter will now have the right to apply his experience on the land.

The owner can always update their experience, however it will not be visible if a rental is in progress.

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
