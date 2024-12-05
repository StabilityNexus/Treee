from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from web3 import Web3
import json

app = FastAPI()

# Connect to the Ethereum network (use a testnet RPC URL)
w3 = Web3(Web3.HTTPProvider('https://rpc.cardona.zkevm-rpc.com'))

# Contract ABI and address
with open('TreeNFTABI.json', 'r') as abi_file:
    contract_abi = json.load(abi_file)
contract_address = '0x1d9a70508F50da7A13659E12A6439fD2F21eDf31'

# Load contract
contract = w3.eth.contract(address=contract_address, abi=contract_abi["abi"])

# Private key (keep it safe and not exposed)
private_key = "ebdda197f79abb97d421cfb3e58a305f95552f4816c536b63caeb4ad7451aa26"
account = w3.eth.account.from_key(private_key)
owner_address = account.address

# Helper function to send transaction


def send_transaction(function, *args):
    # Build the transaction
    txn = function.build_transaction({
        'from': owner_address,
        'gas': 2000000,
        'gasPrice': 2000000,
        'nonce': w3.eth.get_transaction_count(owner_address),
    })

    # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(txn, private_key)

    # Send the transaction
    txn_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
    print(receipt)
    if receipt['status'] == 1:  # If the transaction is successful
        return txn_hash.hex()
    else:
        raise HTTPException(
            status_code=500, detail="Minting transaction failed")

# Define a request model for minting


class MintRequest(BaseModel):
    to_address: str
    token_uri: str


@app.post("/mint_nft")
async def mint_nft(mint_request: MintRequest):
    # Get minting function from contract
    next_token_id = contract.functions.nextTokenId().call()
    mint_function = contract.functions.mint(
        mint_request.to_address, mint_request.token_uri)

    # Send transaction to mint the NFT
    try:
        txn_hash = send_transaction(mint_function)
        return {"status": "success", "transaction_hash": txn_hash, "token_id": next_token_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/token_uri/{token_id}")
async def get_token_uri(token_id: int):
    # Get token URI from contract
    token_uri = contract.functions.tokenURI(token_id).call()
    try:
        token_uri = contract.functions.tokenURI(token_id).call()
        return {"token_id": token_id, "token_uri": token_uri}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
