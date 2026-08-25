global class L2L3ProductBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        L2L3ProductBatch b = new L2L3ProductBatch();
        Database.executeBatch(b,200);
    }
}