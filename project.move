module MyModule::LayawayService {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a layaway plan
    struct LayawayPlan has store, key {
        locked_price: u64,        // Price locked in at plan creation (in APT)
        total_amount: u64,        // Total amount to be paid
        paid_amount: u64,         // Amount already paid
        payment_interval: u64,    // Payment interval in seconds
        next_payment_due: u64,    // Timestamp for next payment
        item_description: vector<u8>, // Description of the item being purchased
    }

    /// Function to create a new layaway plan with locked-in price
    public fun create_layaway_plan(
        buyer: &signer, 
        locked_price: u64, 
        total_amount: u64,
        payment_interval: u64,
        item_description: vector<u8>
    ) {
        let current_time = timestamp::now_seconds();
        let plan = LayawayPlan {
            locked_price,
            total_amount,
            paid_amount: 0,
            payment_interval,
            next_payment_due: current_time + payment_interval,
            item_description,
        };
        move_to(buyer, plan);
    }

    /// Function to make periodic payments towards the layaway plan
    public fun make_payment(
        buyer: &signer, 
        payment_amount: u64, 
        merchant_address: address
    ) acquires LayawayPlan {
        let buyer_addr = signer::address_of(buyer);
        let plan = borrow_global_mut<LayawayPlan>(buyer_addr);
        let current_time = timestamp::now_seconds();
        
        // Check if payment is due
        assert!(current_time >= plan.next_payment_due, 1);
        
        // Transfer payment from buyer to merchant
        let payment = coin::withdraw<AptosCoin>(buyer, payment_amount);
        coin::deposit<AptosCoin>(merchant_address, payment);
        
        // Update plan details
        plan.paid_amount = plan.paid_amount + payment_amount;
        plan.next_payment_due = current_time + plan.payment_interval;
        
        // Check if fully paid
        assert!(plan.paid_amount <= plan.total_amount, 2);
    }
}