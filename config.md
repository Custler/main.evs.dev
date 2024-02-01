## Fields definition in node config file
------------
### Sections:

* ### `log_config_name`
    Filename with path to yaml log config file

* ### `ton_global_config_name`
        Filename with path to network global config file 
        with IP, port and pubkeys root nodes in network

* ### `internal_db_path`
    Path to save node database

* ### `validation_countdown_mode`

* ### `unsafe_catchain_patches_path`

* ### `adnl_node`
        `ip_address`  - "IP:PORT" of the node
        `keys`        - ADNL keys of the node
        `recv_pipeline_pool` - 
        `recv_priority_pool` -
        `telemetry_peer_packets` -
        `throughput` -
        `timeout_check_packet_processing_mcs` -
        `timeout_expire_queued_packet_sec` -

* ### `validator_keys`
        Keys for the current and upcoming election rounds:
            `election_id`  - election id as unix time
            `validator_key_id` - pubkey sent to elector
            `validator_adnl_key_id` - ADNL key sent to elector 

* ### `control_server`
        `address`     - "IP:PORT" node listen for console connection
        `clients`     - list of consoles  pubkeys allowed connection
        `server_key`  - private key of the node to secure console connection
------------
* ### `kafka_consumer_config:`
    * #### `group_id`
    * #### `brokers`
    * #### `topic`
    * #### `session_timeout_ms`
    * #### `run_attempt_timeout_ms`

* ### `external_db_config`
    * #### `block_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `raw_block_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `message_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `transaction_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `account_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `block_proof_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `raw_block_proof_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `chain_range_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `remp_statuses_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `shard_hashes_producer`
      * #### `enabled`
      * #### `brokers`
      * #### `message_timeout_ms`
      * #### `topic`
      * #### `sharded_topics`
      * #### `sharding_depth`
      * #### `attempt_timeout_ms`
      * #### `message_max_size`
      * #### `big_messages_storage`
      * #### `big_message_max_size`
      * #### `external_message_ref_address_prefix`

    * #### `bad_blocks_storage": "bad-blocks"`
------------
* ### `default_rldp_roundtrip_ms``
* ### `test_bundles_config`
    * #### `collator`
      * #### `build_for_unknown_errors`
      * #### `known_errors`
      * #### `build_for_errors`
      * #### `errors`
      * #### `path": ""

    * #### `validator`
      * #### `build_for_unknown_errors`
      * #### `known_errors`
      * #### `build_for_errors`
      * #### `errors`
      * #### `path": ""

* ### `connectivity_check_config`
    * #### `enabled`
    * #### `long_len`
    * #### `short_period_ms`
    * #### `long_mult'
------------
* ### `gc:`
    * #### `enable_for_archives"`
    * #### `archives_life_time_hours`
    * #### `enable_for_shard_state_persistent`
    * #### `cells_gc_config:`
      * ##### `gc_interval_sec`
      * ##### `cells_lifetime_sec`
 
* ### `validator_key_ring`
    * #### `\<pubkey in base64\>: `
      * ##### `type_id`
      * ##### `pub_key`
      * ##### `pvt_key": "\<private key in base64\>`

* ### `remp`
    * #### `service_enabled`
        Possible values `true` and `false`. 
        Enables participation in validator REMP protocols. Default value is `true`.

        The service allows the node to validate in REMP networks, but does not affect validation
        in non-REMP networks. So if the Network REMP capability is turned off now but may be activated 
        in the future, leave the default value.

        However, REMP protocols take some resources from the node even if the REMP capability is
        turned off. If the node is not expected to be a validator in REMP network,
        set this to `false`.

    * #### `client_enabled`
        Possible values `true` and `false`. Default value `true`.
        Enables participation in client REMP protocols. With this option
        set to `false`, the node may not send external messages to 
        REMP network. As with `service_enabled` parameter, the client service is transparent
        for non-REMP networks, but may take extra hardware resources.

    * #### `message_queue_max_len`
        non-negative integer value.
        When specified, sets maximal number of external messages
        which can be handled by REMP simultaneously. Handling means all 
        message processing stages from its receiving by node till
        its expiration for replay protection purposes. The message count
        is performed for each shard separately.

        May be used to avoid node overloading by external messages. If the  
        queue becomes too long, all new messages are rejected, until some of the 
        messages from the queue become outdated (that is, their replay protection 
        period expires).

        If the value is not specified, no check of the message queue length is performed.
  
    * #### `forcedly_disable_remp_cap`
        Possible values `true` and `false`. The parameter is
        available only in `remp_emergency` compilation configuration. Allows to locally 
        disable REMP capability even if the capability is enabled by the network. May be
        used for network recovery.

    * #### `remp_client_pool`
        Integer value 0 to 255. Number of threads (as a percentage of CPU Cores number), 
        used for preliminary message processing in REMP client.
        Default value is 100% (the number of threads equals the number of CPU Cores). 
        At least one thread is started anyway.

        Before being sent to validators, any external REMP message is executed in test mode on a client
        (proper blockchain state is constructed, virtual machine is activated etc), and if the message
        processing results in error, it is rejected on the client and not sent to validators.

    * #### `max_incoming_broadcast_delay_millis`
        Non-negative integer value. When external 
        messages are sent to validators via broadcast (legacy mechanism), they come to all nodes 
        in the network simultaneously, which may create a significant overload in 
        REMP Catchain. To overcome this, the messages coming to the validators may be 
        delayed for a random time, in a hope that only one copy of the message is
        processed and transferred to REMP Catchain. The random time distribution of the message
        copies gives enough time for the network to propagate message over it, so copies delayed
        for longer periods will be easily identified as duplicates (the validator will
        already have the same message received through Catchain from another validtor). 
        The parameter specifies maximal delay. 

* ### `restore_db`
        Possible values `true` and `false`.

* ### `low_memory_mode`
        Possible values `true` and `false`.

* ### `cells_db_config:`
    * #### `states_db_queue_len`
    * #### `max_pss_slowdown_mcs`
    * #### `prefill_cells_counters`
    * #### `cache_cells_counters`
    * #### `cache_size_bytes`

* ### `collator_config:`
    * #### `cutoff_timeout_ms`
    * #### `stop_timeout_ms`
    * #### `clean_timeout_percentage_points`
    * #### `optimistic_clean_percentage_points`
    * #### `max_secondary_clean_timeout_percentage_points`
    * #### `max_collate_threads`
    * #### `retry_if_empty`
    * #### `finalize_empty_after_ms`
    * #### `empty_collation_sleep_ms`
    * #### `external_messages_timeout_percentage_points`

* ### `skip_saving_persistent_states`

* ### `states_cache_mode:`
        Possible values:
        * #### `Off" - states are saved synchronously and not cached.
        * #### `Moderate" - recommended - states are saved asiynchronously. Number of cached cells (in the state's BOCs) is minimal.
        * #### `Full" - states saved asynchronously. The number of cells in memory is continuously growing.

* ### `states_cache_cleanup_diff`
