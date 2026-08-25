/*
Name : CreatePartListControllerTestMock
Description : Mock Test class for CreatePartListController.
Author : Pavan
*/


@isTest
global class CreatePartListControllerTestMock implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
       String responseType) {
           
           PartListWebServiceNew.ZplmsgSfdc testZplmsgSfdc = new PartListWebServiceNew.ZplmsgSfdc();
           testZplmsgSfdc.Matnr= 'test';
           testZplmsgSfdc.Error = 'test';
           testZplmsgSfdc.Msgtxt = 'test';
           
           List<PartListWebServiceNew.ZplmsgSfdc> lstZplmsgSfdc = new  List<PartListWebServiceNew.ZplmsgSfdc>();
           lstZplmsgSfdc.add(testZplmsgSfdc);
           
           PartListWebServiceNew.TableOfZplmsgSfdc testTableOfZplmsgSfdc = new PartListWebServiceNew.TableOfZplmsgSfdc();
           testTableOfZplmsgSfdc.item = lstZplmsgSfdc;
           
           PartListWebServiceNew.ZplmspSfdc testZplmspSfdc= new PartListWebServiceNew.ZplmspSfdc();
           testZplmspSfdc.SalesOrder = '0000007944';
           testZplmspSfdc.OrderDate = '2010-10-30';
           testZplmspSfdc.OfferNo = '20037871';
           testZplmspSfdc.ZDmatnr = 'SP-00000';
           testZplmspSfdc.SalesPrice = '2997';
           
           List<PartListWebServiceNew.ZplmspSfdc> lstZplmspSfdc = new List<PartListWebServiceNew.ZplmspSfdc>();
           lstZplmspSfdc.add(testZplmspSfdc);
           
           PartListWebServiceNew.TableOfZplmspSfdc testTableOfZplmspSfdc = new PartListWebServiceNew.TableOfZplmspSfdc();
           testTableOfZplmspSfdc.item=lstZplmspSfdc;
           
           PartListWebServiceNew.Zpltab1Sfdc testZpltab1Sfdc = new PartListWebServiceNew.Zpltab1Sfdc();
           testZpltab1Sfdc.ZGmatnr = 'test';
           testZpltab1Sfdc.Gdesc = 'test';
           testZpltab1Sfdc.Waers = 'INR';
           testZpltab1Sfdc.SfdcId = '';
           testZpltab1Sfdc.Ztext = 'Test';
           testZpltab1Sfdc.Plifz = '1234';
           testZpltab1Sfdc.LofNum = 'Test';
           testZpltab1Sfdc.LofVal = '1234';
           testZpltab1Sfdc.Revstatus = '1234';
           testZpltab1Sfdc.HsnCode = 'Test';
           testZpltab1Sfdc.Exrate = '1234';
           testZpltab1Sfdc.Revstatus = '10';
           
           List<PartListWebServiceNew.Zpltab1Sfdc> lstZpltab1Sfdc = new List<PartListWebServiceNew.Zpltab1Sfdc>();
           lstZpltab1Sfdc.add(testZpltab1Sfdc);
           
           PartListWebServiceNew.TableOfZpltab1Sfdc testTableOfZpltab1Sfdc = new PartListWebServiceNew.TableOfZpltab1Sfdc();
           testTableOfZpltab1Sfdc.item = lstZpltab1Sfdc;
           
           PartListWebServiceNew.Zpltab2Sfdc testZpltab2Sfdc = new PartListWebServiceNew.Zpltab2Sfdc();
           testZpltab2Sfdc.ZMmatnr = 'YS-67-06234-O';
           testZpltab2Sfdc.Mdesc = 'ST-OF-PU-APP-1080X860X31-8/12X68-TD-BD';
           testZpltab2Sfdc.HsnCode = 'ST-OF-PU-APP-1080X860X31-8/12X68-TD-BD';
           testZpltab2Sfdc.Menge = '10';
           testZpltab2Sfdc.Meins = 'Each';
           
           List<PartListWebServiceNew.Zpltab2Sfdc> listZpltab2Sfdc = new List<PartListWebServiceNew.Zpltab2Sfdc>();
           listZpltab2Sfdc.add(testZpltab2Sfdc);
           
           PartListWebServiceNew.TableOfZpltab2Sfdc testTableOfZpltab2Sfdc = new PartListWebServiceNew.TableOfZpltab2Sfdc();
           testTableOfZpltab2Sfdc.item=listZpltab2Sfdc;
           
           PartListWebServiceNew.Zpltab3Sfdc testZpltab3Sfdc = new PartListWebServiceNew.Zpltab3Sfdc();
           testZpltab3Sfdc.ZMmatnr = 'YS-67-06234-O';
           testZpltab3Sfdc.Ddesc = 'ST-OF-PU-APP-1080X860X31-8/12X68-TD-BD';
           testZpltab3Sfdc.HsnCode = 'ST-OF-PU-APP-1080X860X31-8/12X68-TD-BD';
           testZpltab3Sfdc.Menge = '10';
           testZpltab3Sfdc.Meins = 'Each';
           testZpltab3Sfdc.Mtart = 'Test';
           testZpltab3Sfdc.Matkl = 'Test';
           testZpltab3Sfdc.Beskz = 'Test';
           testZpltab3Sfdc.Zeinr ='Test';
           
           List<PartListWebServiceNew.Zpltab3Sfdc> lstZpltab3Sfdc = new List<PartListWebServiceNew.Zpltab3Sfdc>();
           lstZpltab3Sfdc.add(testZpltab3Sfdc);
           
           PartListWebServiceNew.TableOfZpltab3Sfdc testTableOfZpltab3Sfdc = new PartListWebServiceNew.TableOfZpltab3Sfdc();
           testTableOfZpltab3Sfdc.item = lstZpltab3Sfdc;
           
           PartListWebServiceNew.ZweightSfdc testZweightSfdc = new PartListWebServiceNew.ZweightSfdc();
           testZweightSfdc.Matnr = 'YS-67-06234-O';
           testZweightSfdc.Ntgew = '50';
           
           List<PartListWebServiceNew.ZweightSfdc> listZweightSfdc = new List<PartListWebServiceNew.ZweightSfdc>();
           listZweightSfdc.add(testZweightSfdc);
           
           PartListWebServiceNew.TableOfZweightSfdc testTableOfZweightSfdc = new PartListWebServiceNew.TableOfZweightSfdc();
           testTableOfZweightSfdc.item= listZweightSfdc;

           PartListWebServiceNew.ZPartlistSfResponse_element testZPartlistSfResponse_element= new PartListWebServiceNew.ZPartlistSfResponse_element();
           testZPartlistSfResponse_element.GtMsg = testTableOfZplmsgSfdc;
           testZPartlistSfResponse_element.GtSp = testTableOfZplmspSfdc;
           testZPartlistSfResponse_element.GtTab1 = testTableOfZpltab1Sfdc;
           testZPartlistSfResponse_element.GtTab2 = testTableOfZpltab2Sfdc;
           testZPartlistSfResponse_element.GtTab3 = testTableOfZpltab3Sfdc;
           testZPartlistSfResponse_element.GtWeight = testTableOfZweightSfdc;
           testZPartlistSfResponse_element.ExMessage = '';
          
           PartListWebServiceNew.ZWSPARTLIST responsey = new PartListWebServiceNew.ZWSPARTLIST();
           response.put('response_x',testZPartlistSfResponse_element);         
       }
}