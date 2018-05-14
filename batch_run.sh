#!/bin/bash

# check features and determine queue size
rm sdn-cert.log ; ./run.sh benchmarks/queue_size.cfg ; ./run.sh --tar

# check influence of testlenght
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/testlength.cfg ; ./run.sh --tar

# determine max throughput
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/fields/match_exact-detailed-inport.cfg ; ./run.sh --tar
# check different field matching combinations
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/fields/match_exact-quick-max_load.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/fields/match_wildcard-quick-max_load.cfg ; ./run.sh --tar
# check different field modification combinations
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/fields/modify-quick-max_load.cfg ; ./run.sh --tar

# check influence of paket size
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/paket_size/paket_size-quick.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/paket_size/paket_size-detailed_1.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/paket_size/paket_size-detailed_2.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/paket_size/paket_size-detailed_3.cfg ; ./run.sh --tar

# determine table size
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/table_size/table_size-quick-low_load.cfg ; ./run.sh --tar
# check influence of table size
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/table_size/table_size-quick-max_load.cfg ; ./run.sh --tar
# check influence of flow position and access pattern on table
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/table_size/table_size-quick-access_pattern.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/table_size/table_size-quick-flow_position.cfg ; ./run.sh --tar
# check influence of how many tables are used
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/tables_used.cfg ; ./run.sh --tar
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/tables_used-advanced.cfg ; ./run.sh --tar

# check influence of how many tables are used
rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/meters_used.cfg ; ./run.sh --tar

rm sdn-cert.log ; ./run.sh --skipfeature benchmarks/table_and_paket_size.cfg ; ./run.sh --tar
