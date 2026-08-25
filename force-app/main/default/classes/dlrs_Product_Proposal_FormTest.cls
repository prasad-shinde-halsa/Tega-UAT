/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Product_Proposal_FormTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Product_Proposal_FormTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Product_Proposal_Form__c());
    }
}