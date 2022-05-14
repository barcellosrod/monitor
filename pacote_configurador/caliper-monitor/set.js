'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for the benchmark round.
 */
class SetWorkload extends WorkloadModuleBase {
    /**
     * Initializes the workload module instance.
     */
    constructor() {
        super();
        this.txIndex = 0;
    }

    /**
     * Assemble TXs for the round.
     * @return {Promise<TxStatus[]>}
     */
    async submitTransaction() {
        this.txIndex++;

        const args = {
            contractId: this.roundArguments.contractId,
            contractVersion: '1',
            contractFunction: 'set',
            contractArguments: ['node1', '{\'CPU\':50,\'MEM\':50,\'STG\':50.0,\'DAT\':\'2020-11-17T00:10:00Z\'}']
        };

        await this.sutAdapter.sendRequests(args);
    }
}

/**
 * Create a new instance of the workload module.
 * @return {WorkloadModuleInterface}
 */
function createWorkloadModule() {
    return new SetWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
