-- Persistent generated migration.

CREATE FUNCTION migrate() RETURNS void AS $$
DECLARE
  next_version int ;
BEGIN
  SELECT stage_two + 1 INTO next_version FROM schema_version ;
  IF next_version = 1 THEN
    EXECUTE 'ALTER TABLE "schema_version" ALTER COLUMN "id" TYPE INT8' ;
    EXECUTE 'CREATe TABLE "pool_hash"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash_raw" hash28type NOT NULL,"view" VARCHAR NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_hash" ADD CONSTRAINT "unique_pool_hash" UNIQUE("hash_raw")' ;
    EXECUTE 'CREATe TABLE "slot_leader"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash" hash28type NOT NULL,"pool_hash_id" INT8 NULL,"description" VARCHAR NOT NULL)' ;
    EXECUTE 'ALTER TABLE "slot_leader" ADD CONSTRAINT "unique_slot_leader" UNIQUE("hash")' ;
    EXECUTE 'ALTER TABLE "slot_leader" ADD CONSTRAINT "slot_leader_pool_hash_id_fkey" FOREIGN KEY("pool_hash_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "block"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash" hash32type NOT NULL,"epoch_no" uinteger NULL,"slot_no" uinteger NULL,"epoch_slot_no" uinteger NULL,"block_no" uinteger NULL,"previous_id" INT8 NULL,"slot_leader_id" INT8 NOT NULL,"size" uinteger NOT NULL,"time" timestamp NOT NULL,"tx_count" INT8 NOT NULL,"proto_major" uinteger NOT NULL,"proto_minor" uinteger NOT NULL,"vrf_key" VARCHAR NULL,"op_cert" hash32type NULL)' ;
    EXECUTE 'ALTER TABLE "block" ADD CONSTRAINT "unique_block" UNIQUE("hash")' ;
    EXECUTE 'ALTER TABLE "block" ADD CONSTRAINT "block_previous_id_fkey" FOREIGN KEY("previous_id") REFERENCES "block"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "block" ADD CONSTRAINT "block_slot_leader_id_fkey" FOREIGN KEY("slot_leader_id") REFERENCES "slot_leader"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "tx"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash" hash32type NOT NULL,"block_id" INT8 NOT NULL,"block_index" uinteger NOT NULL,"out_sum" entropic NOT NULL,"fee" entropic NOT NULL,"deposit" INT8 NOT NULL,"size" uinteger NOT NULL,"invalid_before" word64type NULL,"invalid_hereafter" word64type NULL)' ;
    EXECUTE 'ALTER TABLE "tx" ADD CONSTRAINT "unique_tx" UNIQUE("hash")' ;
    EXECUTE 'ALTER TABLE "tx" ADD CONSTRAINT "tx_block_id_fkey" FOREIGN KEY("block_id") REFERENCES "block"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "stake_address"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash_raw" addr29type NOT NULL,"view" VARCHAR NOT NULL,"registered_tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "stake_address" ADD CONSTRAINT "unique_stake_address" UNIQUE("hash_raw")' ;
    EXECUTE 'ALTER TABLE "stake_address" ADD CONSTRAINT "stake_address_registered_tx_id_fkey" FOREIGN KEY("registered_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "tx_out"("id" SERIAL8  PRIMARY KEY UNIQUE,"tx_id" INT8 NOT NULL,"index" txindex NOT NULL,"address" VARCHAR NOT NULL,"address_raw" BYTEA NOT NULL,"payment_cred" hash28type NULL,"stake_address_id" INT8 NULL,"value" entropic NOT NULL)' ;
    EXECUTE 'ALTER TABLE "tx_out" ADD CONSTRAINT "unique_txout" UNIQUE("tx_id","index")' ;
    EXECUTE 'ALTER TABLE "tx_out" ADD CONSTRAINT "tx_out_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "tx_out" ADD CONSTRAINT "tx_out_stake_address_id_fkey" FOREIGN KEY("stake_address_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "tx_in"("id" SERIAL8  PRIMARY KEY UNIQUE,"tx_in_id" INT8 NOT NULL,"tx_out_id" INT8 NOT NULL,"tx_out_index" txindex NOT NULL)' ;
    EXECUTE 'ALTER TABLE "tx_in" ADD CONSTRAINT "unique_txin" UNIQUE("tx_out_id","tx_out_index")' ;
    EXECUTE 'ALTER TABLE "tx_in" ADD CONSTRAINT "tx_in_tx_in_id_fkey" FOREIGN KEY("tx_in_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "tx_in" ADD CONSTRAINT "tx_in_tx_out_id_fkey" FOREIGN KEY("tx_out_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "meta"("id" SERIAL8  PRIMARY KEY UNIQUE,"start_time" timestamp NOT NULL,"network_name" VARCHAR NOT NULL)' ;
    EXECUTE 'ALTER TABLE "meta" ADD CONSTRAINT "unique_meta" UNIQUE("start_time")' ;
    EXECUTE 'CREATe TABLE "epoch"("id" SERIAL8  PRIMARY KEY UNIQUE,"out_sum" word128type NOT NULL,"fees" entropic NOT NULL,"tx_count" uinteger NOT NULL,"blk_count" uinteger NOT NULL,"no" uinteger NOT NULL,"start_time" timestamp NOT NULL,"end_time" timestamp NOT NULL)' ;
    EXECUTE 'ALTER TABLE "epoch" ADD CONSTRAINT "unique_epoch" UNIQUE("no")' ;
    EXECUTE 'CREATe TABLE "bccxx_pots"("id" SERIAL8  PRIMARY KEY UNIQUE,"slot_no" uinteger NOT NULL,"epoch_no" uinteger NOT NULL,"treasury" entropic NOT NULL,"reserves" entropic NOT NULL,"rewards" entropic NOT NULL,"utxo" entropic NOT NULL,"deposits" entropic NOT NULL,"fees" entropic NOT NULL,"block_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "bcc_pots" ADD CONSTRAINT "unique_bcc_pots" UNIQUE("block_id")' ;
    EXECUTE 'ALTER TABLE "bcc_pots" ADD CONSTRAINT "bcc_pots_block_id_fkey" FOREIGN KEY("block_id") REFERENCES "block"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_metadata_ref"("id" SERIAL8  PRIMARY KEY UNIQUE,"pool_id" INT8 NOT NULL,"url" VARCHAR NOT NULL,"hash" hash32type NOT NULL,"registered_tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_metadata_ref" ADD CONSTRAINT "unique_pool_metadata_ref" UNIQUE("pool_id","hash")' ;
    EXECUTE 'ALTER TABLE "pool_metadata_ref" ADD CONSTRAINT "pool_metadata_ref_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE RESTRICT  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_metadata_ref" ADD CONSTRAINT "pool_metadata_ref_registered_tx_id_fkey" FOREIGN KEY("registered_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_update"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"vrf_key_hash" hash32type NOT NULL,"pledge" entropic NOT NULL,"reward_addr" addr29type NOT NULL,"active_epoch_no" INT8 NOT NULL,"meta_id" INT8 NULL,"margin" DOUBLE PRECISION NOT NULL,"fixed_cost" entropic NOT NULL,"registered_tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_update" ADD CONSTRAINT "unique_pool_update" UNIQUE("hash_id","registered_tx_id")' ;
    EXECUTE 'ALTER TABLE "pool_update" ADD CONSTRAINT "pool_update_hash_id_fkey" FOREIGN KEY("hash_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_update" ADD CONSTRAINT "pool_update_meta_id_fkey" FOREIGN KEY("meta_id") REFERENCES "pool_metadata_ref"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_update" ADD CONSTRAINT "pool_update_registered_tx_id_fkey" FOREIGN KEY("registered_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_owner"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"pool_hash_id" INT8 NOT NULL,"registered_tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_owner" ADD CONSTRAINT "unique_pool_owner" UNIQUE("addr_id","pool_hash_id","registered_tx_id")' ;
    EXECUTE 'ALTER TABLE "pool_owner" ADD CONSTRAINT "pool_owner_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_owner" ADD CONSTRAINT "pool_owner_pool_hash_id_fkey" FOREIGN KEY("pool_hash_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_owner" ADD CONSTRAINT "pool_owner_registered_tx_id_fkey" FOREIGN KEY("registered_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_retire"("id" SERIAL8  PRIMARY KEY UNIQUE,"hash_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"announced_tx_id" INT8 NOT NULL,"retiring_epoch" uinteger NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_retire" ADD CONSTRAINT "unique_pool_retiring" UNIQUE("hash_id","announced_tx_id")' ;
    EXECUTE 'ALTER TABLE "pool_retire" ADD CONSTRAINT "pool_retire_hash_id_fkey" FOREIGN KEY("hash_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_retire" ADD CONSTRAINT "pool_retire_announced_tx_id_fkey" FOREIGN KEY("announced_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_relay"("id" SERIAL8  PRIMARY KEY UNIQUE,"update_id" INT8 NOT NULL,"ipv4" VARCHAR NULL,"ipv6" VARCHAR NULL,"dns_name" VARCHAR NULL,"dns_srv_name" VARCHAR NULL,"port" INT4 NULL)' ;
    EXECUTE 'ALTER TABLE "pool_relay" ADD CONSTRAINT "unique_pool_relay" UNIQUE("update_id","ipv4","ipv6","dns_name")' ;
    EXECUTE 'ALTER TABLE "pool_relay" ADD CONSTRAINT "pool_relay_update_id_fkey" FOREIGN KEY("update_id") REFERENCES "pool_update"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "reserve"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"amount" int65type NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "reserve" ADD CONSTRAINT "unique_reserves" UNIQUE("addr_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "reserve" ADD CONSTRAINT "reserve_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "reserve" ADD CONSTRAINT "reserve_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "withdrawal"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"amount" entropic NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "withdrawal" ADD CONSTRAINT "unique_withdrawal" UNIQUE("addr_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "withdrawal" ADD CONSTRAINT "withdrawal_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "withdrawal" ADD CONSTRAINT "withdrawal_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "delegation"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"pool_hash_id" INT8 NOT NULL,"active_epoch_no" INT8 NOT NULL,"tx_id" INT8 NOT NULL,"slot_no" uinteger NOT NULL)' ;
    EXECUTE 'ALTER TABLE "delegation" ADD CONSTRAINT "unique_delegation" UNIQUE("addr_id","pool_hash_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "delegation" ADD CONSTRAINT "delegation_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "delegation" ADD CONSTRAINT "delegation_pool_hash_id_fkey" FOREIGN KEY("pool_hash_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "delegation" ADD CONSTRAINT "delegation_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "stake_registration"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "stake_registration" ADD CONSTRAINT "unique_stake_registration" UNIQUE("addr_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "stake_registration" ADD CONSTRAINT "stake_registration_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "stake_registration" ADD CONSTRAINT "stake_registration_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "stake_deregistration"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "stake_deregistration" ADD CONSTRAINT "unique_stake_deregistration" UNIQUE("addr_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "stake_deregistration" ADD CONSTRAINT "stake_deregistration_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "stake_deregistration" ADD CONSTRAINT "stake_deregistration_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "tx_metadata"("id" SERIAL8  PRIMARY KEY UNIQUE,"key" word64type NOT NULL,"json" jsonb NULL,"bytes" bytea NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "tx_metadata" ADD CONSTRAINT "unique_tx_metadata" UNIQUE("key","tx_id")' ;
    EXECUTE 'ALTER TABLE "tx_metadata" ADD CONSTRAINT "tx_metadata_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "reward"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"type" rewardtype NOT NULL,"amount" entropic NOT NULL,"epoch_no" INT8 NOT NULL,"pool_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "reward" ADD CONSTRAINT "unique_reward" UNIQUE("addr_id","epoch_no")' ;
    EXECUTE 'ALTER TABLE "reward" ADD CONSTRAINT "reward_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "reward" ADD CONSTRAINT "reward_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "orphaned_reward"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"type" rewardtype NOT NULL,"amount" entropic NOT NULL,"epoch_no" INT8 NOT NULL,"pool_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "orphaned_reward" ADD CONSTRAINT "unique_orphaned" UNIQUE("addr_id","epoch_no")' ;
    EXECUTE 'ALTER TABLE "orphaned_reward" ADD CONSTRAINT "orphaned_reward_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "orphaned_reward" ADD CONSTRAINT "orphaned_reward_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "epoch_stake"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"pool_id" INT8 NOT NULL,"amount" entropic NOT NULL,"epoch_no" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "epoch_stake" ADD CONSTRAINT "unique_stake" UNIQUE("addr_id","epoch_no")' ;
    EXECUTE 'ALTER TABLE "epoch_stake" ADD CONSTRAINT "epoch_stake_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "epoch_stake" ADD CONSTRAINT "epoch_stake_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "treasury"("id" SERIAL8  PRIMARY KEY UNIQUE,"addr_id" INT8 NOT NULL,"cert_index" INT4 NOT NULL,"amount" int65type NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "treasury" ADD CONSTRAINT "unique_treasury" UNIQUE("addr_id","tx_id")' ;
    EXECUTE 'ALTER TABLE "treasury" ADD CONSTRAINT "treasury_addr_id_fkey" FOREIGN KEY("addr_id") REFERENCES "stake_address"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "treasury" ADD CONSTRAINT "treasury_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pot_transfer"("id" SERIAL8  PRIMARY KEY UNIQUE,"cert_index" INT4 NOT NULL,"treasury" int65type NOT NULL,"reserves" int65type NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pot_transfer" ADD CONSTRAINT "unique_pot_transfer" UNIQUE("tx_id","cert_index")' ;
    EXECUTE 'ALTER TABLE "pot_transfer" ADD CONSTRAINT "pot_transfer_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "ma_tx_mint"("id" SERIAL8  PRIMARY KEY UNIQUE,"policy" hash28type NOT NULL,"name" asset32type NOT NULL,"quantity" int65type NOT NULL,"tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "ma_tx_mint" ADD CONSTRAINT "unique_ma_tx_mint" UNIQUE("policy","name","tx_id")' ;
    EXECUTE 'ALTER TABLE "ma_tx_mint" ADD CONSTRAINT "ma_tx_mint_tx_id_fkey" FOREIGN KEY("tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "ma_tx_out"("id" SERIAL8  PRIMARY KEY UNIQUE,"policy" hash28type NOT NULL,"name" asset32type NOT NULL,"quantity" word64type NOT NULL,"tx_out_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "ma_tx_out" ADD CONSTRAINT "unique_ma_tx_out" UNIQUE("policy","name","tx_out_id")' ;
    EXECUTE 'ALTER TABLE "ma_tx_out" ADD CONSTRAINT "ma_tx_out_tx_out_id_fkey" FOREIGN KEY("tx_out_id") REFERENCES "tx_out"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "param_proposal"("id" SERIAL8  PRIMARY KEY UNIQUE,"epoch_no" uinteger NOT NULL,"key" hash28type NOT NULL,"min_fee_a" uinteger NULL,"min_fee_b" uinteger NULL,"max_block_size" uinteger NULL,"max_tx_size" uinteger NULL,"max_bh_size" uinteger NULL,"key_deposit" entropic NULL,"pool_deposit" entropic NULL,"max_epoch" uinteger NULL,"optimal_pool_count" uinteger NULL,"influence" DOUBLE PRECISION NULL,"monetary_expand_rate" DOUBLE PRECISION NULL,"treasury_growth_rate" DOUBLE PRECISION NULL,"decentralisation" DOUBLE PRECISION NULL,"entropy" hash32type NULL,"protocol_major" uinteger NULL,"protocol_minor" uinteger NULL,"min_utxo_value" entropic NULL,"min_pool_cost" entropic NULL,"registered_tx_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "param_proposal" ADD CONSTRAINT "unique_param_proposal" UNIQUE("key","registered_tx_id")' ;
    EXECUTE 'ALTER TABLE "param_proposal" ADD CONSTRAINT "param_proposal_registered_tx_id_fkey" FOREIGN KEY("registered_tx_id") REFERENCES "tx"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "epoch_param"("id" SERIAL8  PRIMARY KEY UNIQUE,"epoch_no" uinteger NOT NULL,"min_fee_a" uinteger NOT NULL,"min_fee_b" uinteger NOT NULL,"max_block_size" uinteger NOT NULL,"max_tx_size" uinteger NOT NULL,"max_bh_size" uinteger NOT NULL,"key_deposit" entropic NOT NULL,"pool_deposit" entropic NOT NULL,"max_epoch" uinteger NOT NULL,"optimal_pool_count" uinteger NOT NULL,"influence" DOUBLE PRECISION NOT NULL,"monetary_expand_rate" DOUBLE PRECISION NOT NULL,"treasury_growth_rate" DOUBLE PRECISION NOT NULL,"decentralisation" DOUBLE PRECISION NOT NULL,"entropy" hash32type NULL,"protocol_major" uinteger NOT NULL,"protocol_minor" uinteger NOT NULL,"min_utxo_value" entropic NOT NULL,"min_pool_cost" entropic NOT NULL,"nonce" hash32type NULL,"block_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "epoch_param" ADD CONSTRAINT "unique_epoch_param" UNIQUE("epoch_no","block_id")' ;
    EXECUTE 'ALTER TABLE "epoch_param" ADD CONSTRAINT "epoch_param_block_id_fkey" FOREIGN KEY("block_id") REFERENCES "block"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_offline_data"("id" SERIAL8  PRIMARY KEY UNIQUE,"pool_id" INT8 NOT NULL,"ticker_name" VARCHAR NOT NULL,"hash" hash32type NOT NULL,"metadata" VARCHAR NOT NULL,"pmr_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_offline_data" ADD CONSTRAINT "unique_pool_offline_data" UNIQUE("pool_id","hash")' ;
    EXECUTE 'ALTER TABLE "pool_offline_data" ADD CONSTRAINT "pool_offline_data_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_offline_data" ADD CONSTRAINT "pool_offline_data_pmr_id_fkey" FOREIGN KEY("pmr_id") REFERENCES "pool_metadata_ref"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "pool_offline_fetch_error"("id" SERIAL8  PRIMARY KEY UNIQUE,"pool_id" INT8 NOT NULL,"fetch_time" timestamp NOT NULL,"pmr_id" INT8 NOT NULL,"fetch_error" VARCHAR NOT NULL,"retry_count" uinteger NOT NULL)' ;
    EXECUTE 'ALTER TABLE "pool_offline_fetch_error" ADD CONSTRAINT "unique_pool_offline_fetch_error" UNIQUE("pool_id","fetch_time","retry_count")' ;
    EXECUTE 'ALTER TABLE "pool_offline_fetch_error" ADD CONSTRAINT "pool_offline_fetch_error_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'ALTER TABLE "pool_offline_fetch_error" ADD CONSTRAINT "pool_offline_fetch_error_pmr_id_fkey" FOREIGN KEY("pmr_id") REFERENCES "pool_metadata_ref"("id") ON DELETE CASCADE  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "reserved_pool_ticker"("id" SERIAL8  PRIMARY KEY UNIQUE,"name" VARCHAR NOT NULL,"pool_id" INT8 NOT NULL)' ;
    EXECUTE 'ALTER TABLE "reserved_pool_ticker" ADD CONSTRAINT "unique_reserved_pool_ticker" UNIQUE("name")' ;
    EXECUTE 'ALTER TABLE "reserved_pool_ticker" ADD CONSTRAINT "reserved_pool_ticker_pool_id_fkey" FOREIGN KEY("pool_id") REFERENCES "pool_hash"("id") ON DELETE RESTRICT  ON UPDATE RESTRICT' ;
    EXECUTE 'CREATe TABLE "admin_user"("id" SERIAL8  PRIMARY KEY UNIQUE,"username" VARCHAR NOT NULL,"password" VARCHAR NOT NULL)' ;
    EXECUTE 'ALTER TABLE "admin_user" ADD CONSTRAINT "unique_admin_user" UNIQUE("username")' ;
    -- Hand written SQL statements can be added here.
    UPDATE schema_version SET stage_two = next_version ;
    RAISE NOTICE 'DB has been migrated to stage_two version %', next_version ;
  END IF ;
END ;
$$ LANGUAGE plpgsql ;

SELECT migrate() ;

DROP FUNCTION migrate() ;
