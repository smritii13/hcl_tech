-- Procedure to update points and last purchase date
CREATE OR REPLACE PROCEDURE update_loyalty_accrual()
LANGUAGE plpgsql
AS $$
DECLARE
    v_per_unit_spend DECIMAL(5, 2);
BEGIN
    -- Get the main loyalty rule
    SELECT per_unit_spend INTO v_per_unit_spend
    FROM retail_hackathon.loyalty_rules
    LIMIT 1;

    -- 1. Calculate points for all transactions that have a customer_id and update customer_details
    WITH new_points AS (
        SELECT
            t.customer_id,
            t.transaction_id,
            -- Calculate accrued points (Total Amount * Points per Unit Spend)
            FLOOR(t.total_amount * v_per_unit_spend)::INT AS accrued_points,
            t.transaction_date::DATE AS purchase_date
        FROM retail_hackathon.store_sales_header t
        WHERE t.customer_id IS NOT NULL 
          -- Assumption: Only process transactions that haven't been credited yet 
          -- (In a real system, you'd track this with a ledger or flag)
    )
    UPDATE retail_hackathon.customer_details cd
    SET 
        total_loyalty_points = COALESCE(cd.total_loyalty_points, 0) + np.accrued_points,
        last_purchase_date = GREATEST(COALESCE(cd.last_purchase_date, np.purchase_date), np.purchase_date)
    FROM new_points np
    WHERE cd.customer_id = np.customer_id
    AND np.accrued_points > 0;

    -- Note: In a production environment, transactions should be marked as 'processed' after this step.
END;
$$;

-- Execute the procedure to run the loyalty calculation
CALL retail_hackathon.update_loyalty_accrual();