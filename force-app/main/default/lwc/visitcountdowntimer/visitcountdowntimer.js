import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// ── Adjust these field API names to match your actual org ──
const CREATED_DATE_FIELD = 'Customer_Visit__c.CreatedDate';
const STATUS_FIELD       = 'Customer_Visit__c.Status__c';
const SUBMITTED_VALUE    = 'Submitted';   // picklist value from your screenshot
const DEADLINE_HOURS     = 48;            // hours before visit is locked out of report

const FIELDS = [CREATED_DATE_FIELD, STATUS_FIELD];

export default class VisitCountdownTimer extends LightningElement {

    @api recordId;

    @track formattedTime = '48:00:00';
    @track isExpired     = false;
    @track showTimer     = true;

    _intervalId   = null;
    _deadlineMs   = null;   // epoch ms when the 48-hr window closes
    _status       = null;

    // ── Wire: load record fields ──────────────────────────────────────────
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            const status      = getFieldValue(data, STATUS_FIELD);
            const createdDate = getFieldValue(data, CREATED_DATE_FIELD);

            this._status = status;

            // If already submitted → hide timer completely
            if (status === SUBMITTED_VALUE) {
                this.showTimer = false;
                this._stopTimer();
                return;
            }

            // Calculate 48-hour deadline from CreatedDate
            if (createdDate) {
                const created      = new Date(createdDate).getTime();
                this._deadlineMs   = created + DEADLINE_HOURS * 60 * 60 * 1000;
                this._startTimer();
            }
        } else if (error) {
            console.error('visitCountdownTimer – wire error:', error);
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────
    disconnectedCallback() {
        this._stopTimer();
    }

    // ── Timer helpers ─────────────────────────────────────────────────────
    _startTimer() {
        this._stopTimer();          // safety: clear any existing interval
        this._tick();               // immediate first render
        this._intervalId = setInterval(() => this._tick(), 1000);
    }

    _stopTimer() {
        if (this._intervalId) {
            clearInterval(this._intervalId);
            this._intervalId = null;
        }
    }

    _tick() {
        if (!this._deadlineMs) return;

        const nowMs       = Date.now();
        const remainingMs = this._deadlineMs - nowMs;

        if (remainingMs <= 0) {
            this.formattedTime = '00:00:00';
            this.isExpired     = true;
            this._stopTimer();
            return;
        }

        this.isExpired     = false;
        this.formattedTime = this._msToHHMMSS(remainingMs);
    }

    _msToHHMMSS(ms) {
        const totalSeconds = Math.floor(ms / 1000);
        const hours        = Math.floor(totalSeconds / 3600);
        const minutes      = Math.floor((totalSeconds % 3600) / 60);
        const seconds      = totalSeconds % 60;
        return [hours, minutes, seconds]
            .map(v => String(v).padStart(2, '0'))
            .join(':');
    }

    // ── Dynamic CSS class ─────────────────────────────────────────────────
    get timerClass() {
        if (this.isExpired) return 'timer-box timer-expired';
        const remainingMs = this._deadlineMs - Date.now();
        const remainingHrs = remainingMs / (1000 * 60 * 60);
        if (remainingHrs <= 6)  return 'timer-box timer-critical';   // red  – < 6 hrs
        if (remainingHrs <= 12) return 'timer-box timer-warning';    // orange – < 12 hrs
        return 'timer-box timer-ok';                                  // green – plenty of time
    }
}