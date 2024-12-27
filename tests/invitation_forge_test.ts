import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new invitation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'create-invitation', [
                types.utf8("Wedding Celebration"),
                types.utf8("Join us for our special day"),
                types.uint(1672531200), // Jan 1, 2023
                types.utf8("Central Park, NY"),
                types.uint(100),
                types.uint(1670531200)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify invitation details
        let getBlock = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'get-invitation', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const invitation = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(invitation['title'], "Wedding Celebration");
    }
});

Clarinet.test({
    name: "Can add guest and submit RSVP",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const guest = accounts.get('wallet_1')!;
        
        // Create invitation
        let block = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'create-invitation', [
                types.utf8("Wedding Celebration"),
                types.utf8("Join us for our special day"),
                types.uint(1672531200),
                types.utf8("Central Park, NY"),
                types.uint(100),
                types.uint(1670531200)
            ], deployer.address)
        ]);
        
        // Add guest
        let addGuestBlock = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'add-guest', [
                types.uint(1),
                types.principal(guest.address)
            ], deployer.address)
        ]);
        
        addGuestBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Submit RSVP
        let rsvpBlock = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'submit-rsvp', [
                types.uint(1),
                types.ascii("accepted"),
                types.uint(2)
            ], guest.address)
        ]);
        
        rsvpBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Cannot update invitation if not owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const other = accounts.get('wallet_1')!;
        
        // Create invitation
        let block = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'create-invitation', [
                types.utf8("Wedding Celebration"),
                types.utf8("Join us for our special day"),
                types.uint(1672531200),
                types.utf8("Central Park, NY"),
                types.uint(100),
                types.uint(1670531200)
            ], deployer.address)
        ]);
        
        // Try to update as non-owner
        let updateBlock = chain.mineBlock([
            Tx.contractCall('invitation-forge', 'update-invitation', [
                types.uint(1),
                types.utf8("Modified Title"),
                types.utf8("Modified Description"),
                types.uint(1672531200),
                types.utf8("New Location"),
                types.uint(100),
                types.uint(1670531200)
            ], other.address)
        ]);
        
        updateBlock.receipts[0].result.expectErr().expectUint(102); // err-unauthorized
    }
});