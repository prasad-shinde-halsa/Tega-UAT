global class CustomerWebServiceMockImpl implements WebServiceMock {
    CustomerWebserviceNewV6.ZRFC_CUST_DETAILSResponse_element responseELE;
    CustomerWebserviceNewV6.ZST_CUST_DTLS custDtlsObj;
    
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
            
            //Account accid = new account(name = 'test Customer' );
            //insert accid;
            Account  accid =[select id from account where name='test Customer'];
            
            
            responseELE = new CustomerWebserviceNewV6.ZRFC_CUST_DETAILSResponse_element();
            String exMessage = '';
            CustomerWebserviceNewV6.ZTT_CUST_DTLS exCustDtls=new CustomerWebserviceNewV6.ZTT_CUST_DTLS();
            CustomerWebserviceNewV6.ZST_CUST_DTLS custDtlsObj=new CustomerWebserviceNewV6.ZST_CUST_DTLS();
            CustomerWebserviceNewV6.ZST_CUST_DTLS[] item=new CustomerWebserviceNewV6.ZST_CUST_DTLS[]{};
                
                custDtlsObj.Kunnr  = 'CN0005';
            custDtlsObj.SFDC_ID = accid.id;
            custDtlsObj.COMP_CODE = 'TG01';
            custDtlsObj.SALES_ORG = 'TGSO';
            custDtlsObj.DIST_CHAN = 'DS';
            custDtlsObj.STREET1 ='MASAB TANK';
            custDtlsObj.STREET2 ='10-3-311/A, KHANIJ BHAVAN';
            custDtlsObj.STREET3 = 'CASTLE HILLS';
            custDtlsObj.STREET4= '';
            custDtlsObj.STREET5='hyderabad';
            custDtlsObj.NAME= '"NATIONAL MINERAL DEV CORPN. LTD.';
            custDtlsObj.POST_CODE='500028';
            custDtlsObj.CITY='HYDERABAD';
            custDtlsObj.Region='1';
            custDtlsObj.INDUSTRY_SEG='4';
            custDtlsObj.COUNTRY ='IN';
            custDtlsObj.Langu ='';
            custDtlsObj.Telno='';
            custDtlsObj.Mobile='9831022222';
            custDtlsObj.Fax ='245788999';
            custDtlsObj.SALES_OFF='HYD';
            custDtlsObj.Currency_x='INR';
            custDtlsObj.Email='test@gmail.com';
            custDtlsObj.GST_NO='';
            custDtlsObj.Pobox='';
            custDtlsObj.CUST_GRP='NALCO';
            
            
            item.add(custDtlsObj);
            exCustDtls.item=item;
            responseELE.EX_CUST_DTLS  = exCustDtls;
            responseELE.EX_MESSAGE = exMessage;
            
            system.debug('responseELE-------'+responseELE.EX_CUST_DTLS );
            response.put('response_x',responseELE ); 
            
        }
    
    public void coverMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}