import { LightningElement, track, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['User.Profile.Name', 'User.DefaultCurrencyIsoCode', 'User.Name', 'User.CurrencyIsoCode'];
import getAllCompany from '@salesforce/apex/MISEntryStatusController.getAllCompany';
import getBranchesForCompany from '@salesforce/apex/MISEntryStatusController.getBranchesForCompany';
import getDCBudgetAndChildItems from '@salesforce/apex/MISEntryStatusController.getDCBudgetAndChildItems';

export default class MISEntryStatus extends LightningElement {

    @track isLoading = false;
    userId = USER_ID;
    profileName;
    @track selectedFY;
    @track financialYearOptions = [];
    @track selectedMonth = '';
    monthOptions = [
        { label: 'April', value: 'April' },
        { label: 'May', value: 'May' },
        { label: 'June', value: 'June' },
        { label: 'July', value: 'July' },
        { label: 'August', value: 'August' },
        { label: 'September', value: 'September' },
        { label: 'October', value: 'October' },
        { label: 'November', value: 'November' },
        { label: 'December', value: 'December' },
        { label: 'January', value: 'January' },
        { label: 'February', value: 'February' },
        { label: 'March', value: 'March' }
    ];

    @track companyOptions = [];
    @track branchOptions = [];

    @track selectedCompany = 'All';
    @track selectedBranch = '';
    @track budgetData = []
    @track allBudgetData = []
    @track showTable = true;


    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            //console.log('⚙️ Raw user data:', JSON.stringify(data, null, 2));
            this.profileName = data.fields.Profile.displayValue || data.fields.Profile.value.fields.Name.value;
            const userName = data.fields.Name.value
            //console.log('🔐 Logged-in Profile:', this.profileName);
            //console.log('🔐 Logged-in user Name:',userName);
        } else if (error) {
            console.error('⚠️ Error fetching profile:', error);
        }
    }

    connectedCallback() {
        this.generateFinancialYears();
        this.loadCompanies();
        this.getAllBudgetAndChildRecords();
    }

    generateFinancialYears() {
        this.isLoading = true;
        this.setDefaultSelectedMonth();
        const today = new Date();
        const currentMonth = today.getMonth() + 1;
        const currentYear = today.getFullYear();
        const fyStartYear = currentMonth >= 4 ? currentYear : currentYear - 1;

        const firstFyStartYear = 2025;
        let options = [];

        for (let year = firstFyStartYear; year <= fyStartYear; year++) {
            const endYear = (year + 1).toString().slice(-2);
            options.push({ label: `${year}-${endYear}`, value: `${year}-${endYear}` });
        }

        this.financialYearOptions = options;
        this.selectedFY = `${fyStartYear}-${(fyStartYear + 1).toString().slice(-2)}`;
        this.isLoading = false;
    }

    setDefaultSelectedMonth() {
        const today = new Date();
        const monthNames = [
            'January', 'February', 'March',
            'April', 'May', 'June',
            'July', 'August', 'September',
            'October', 'November', 'December'
        ];
        const currentMonthName = monthNames[today.getMonth()];
        this.selectedMonth = currentMonthName;
    }

    // Load all Company__c records
    loadCompanies() {
        this.isLoading = true;
        getAllCompany()
            .then(data => {
                const options = data.map(company => ({
                    label: company.Name,
                    value: company.Id
                }));

                // Prepend "All"
                this.companyOptions = [{ label: 'All', value: 'All' }, ...options];
            })
            .catch(error => {
                console.error('Error loading companies:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    getAllBudgetAndChildRecords() {
        this.isLoading = true;
        
        getDCBudgetAndChildItems({ selectedFY: this.selectedFY })
            .then(result => {
                this.allBudgetData = result
                    console.log('1st result',JSON.stringify(this.allBudgetData))
            })
            .catch(error => {
                console.error('Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
                this.applyFilters()
            });
    }
    applyFilters() {
    if (!this.selectedMonth) return;

    console.log('Selected branch', this.selectedBranch);
    const monthNameToNumber = {
        'January': 0, 'February': 1, 'March': 2,
        'April': 3, 'May': 4, 'June': 5,
        'July': 6, 'August': 7, 'September': 8,
        'October': 9, 'November': 10, 'December': 11
    };
    const selectedMonthIndex = monthNameToNumber[this.selectedMonth];
    console.log('selectedMonthIndex###', selectedMonthIndex)

    this.budgetData = this.allBudgetData
        .filter(budget => {
            const matchCompany = this.selectedCompany === 'All' || budget.Company__c === this.selectedCompany;
            const matchBranch = this.selectedBranch === '' || this.selectedBranch === 'All' || budget.Branch__c === this.selectedBranch;
            console.log(`🔍 Budget ${budget.Name}: Company Match = ${matchCompany}, Branch Match = ${matchBranch}`);
            return matchCompany && matchBranch;
        })
        .map((budget, index) => {
            const fullName = budget.Name || '';
            const nameParts = fullName.split(/\s*-\s*/);
            const employeeName = nameParts.length >= 4 ? nameParts[2].trim() : '';

            let showMR = false;
            let CreatedByName = '';

            const lineItems = budget.Budget_Line_Items__r || [];
            for (const bli of lineItems) {
                const misBudgets = bli.MIS_Budgets__r || [];
                for (const mis of misBudgets) {
                    const misDateStr = mis.Mis_Monthly_Report__c;
                    if (misDateStr) {
                        const misDate = new Date(misDateStr);
                        const month = misDate.getMonth()
                        console.log('Month###', month)
                        if (misDate.getMonth() === selectedMonthIndex) {
                            showMR = true;
                            CreatedByName = mis.CreatedBy.Name
                            break;
                        }
                    }
                }
                if (showMR) break;
            }

            return {
                slNo: index + 1,
                id: budget.Id,
                branchName: budget.Branch_Name__c || '',
                employeeName: employeeName,
                mrBranchName: showMR ? (budget.Branch_Name__c || '--') : '--',
                mrEmployeeName: showMR ? CreatedByName : '--',
                showMR: showMR,
                viewBudgetLink: `/lightning/r/DC_Budget__c/${budget.Id}/view`,
                viewMRLink: `/lightning/r/DC_Budget__c/${budget.Id}/view`
            };
        });

    this.showTable = this.budgetData.length > 0;
}



    // On Company change, fetch related branches
    handleCompanyChange(event) {
        this.isLoading = true;
        this.selectedCompany = event.detail.value;
        this.selectedBranch = '';
        this.branchOptions = [];

        // If "All" is selected, show "All" in branches only (or skip loading specific branches)
        if (this.selectedCompany === 'All') {
            this.branchOptions = [{ label: 'All', value: 'All' }];
            return;
        }

        getBranchesForCompany({ companyId: this.selectedCompany })
            .then(data => {
                const options = data.map(rel => ({
                    label: rel.Branch__r.Name,
                    value: rel.Branch__r.Id
                }));

                // Prepend "All"
                this.branchOptions = [{ label: 'All', value: 'All' }, ...options];
                this.selectedBranch = 'All';

            })
            .catch(error => {
                console.error('Error loading branches:', error);
            })
            .finally(() => {
                this.isLoading = false;
                this.applyFilters()
            });
    }


    handleBranchChange(event) {
        this.selectedBranch = event.detail.value;
        this.applyFilters()
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        this.applyFilters()
    }
    handleFYChange(event) {
        this.selectedFY = event.detail.value;
        this.getAllBudgetAndChildRecords();
    }

}