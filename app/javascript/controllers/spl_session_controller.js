// app/javascript/controllers/spl_session_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "passwordTab", "otpTab",
    "passwordPanel", "otpPanel",
    // Password login form
    "loginForm",
    "loginSubmitBtn", "loginSubmitLoader",
    "pwdField", "eyeIcon",
    // OTP email step
    "otpEmailStep", "otpEmailField",
    "sendLoginOtpBtn", "sendLoginOtpLoader",
    "otpEmailError", "otpEmailErrorText",
    // OTP verify step
    "otpVerifyStep", "loginOtpEmailDisplay",
    "otpBox",
    "verifyLoginOtpBtn", "verifyLoginLoader",
    "loginOtpError", "loginOtpErrorText",
    "resendLoginBtn", "loginCountdown",
  ]

  static values = {
    sendOtpUrl:   String,
    verifyOtpUrl: String,
  }

  connect() {
    this._countdownTimer = null
  }

  disconnect() {
    if (this._countdownTimer) clearInterval(this._countdownTimer)
  }

  // ── Login mode toggle ────────────────────────────────────────

  showPassword() {
    this._showTarget(this.passwordPanelTarget)
    this._hideTarget(this.otpPanelTarget)
    this.passwordTabTarget.classList.add("active")
    this.otpTabTarget.classList.remove("active")
  }

  showOtp() {
    this._hideTarget(this.passwordPanelTarget)
    this._showTarget(this.otpPanelTarget)
    this.otpTabTarget.classList.add("active")
    this.passwordTabTarget.classList.remove("active")
    this._showTarget(this.otpEmailStepTarget)
    this._hideTarget(this.otpVerifyStepTarget)
  }

  // ── Password login via fetch ─────────────────────────────────
  //
  // THE KEY FIX: Devise's `create` action does an HTML redirect on
  // success and renders HTML flash errors on failure.  We intercept
  // the form submit and POST via fetch so we can show a toast on
  // error and follow the redirect_url on success gracefully.

  async submitLogin(event) {
    event.preventDefault()

    const form = this.loginFormTarget
    if (!form) return

    this._setLoading(this.loginSubmitBtnTarget, this.loginSubmitLoaderTarget, true)

    try {
      const formData = new FormData(form)

      const res = await fetch(form.action, {
        method:  "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept":       "application/json",
        },
        body: formData,
      })

      // Devise's SessionsController#create responds with redirect on success.
      // With Accept: application/json it will still 302, fetch follows it.
      // If the final URL is the dashboard → success.
      // If Devise returns 401/422 with JSON errors → show toast.

      if (res.ok) {
        // Successful sign in — navigate to wherever Devise redirected us
        window.location.href = res.url
      } else {
        let msg = "Invalid email or password"
        try {
          const data = await res.json()
          msg = data.error || data.message || msg
        } catch { /* non-JSON error body */ }
        this._showToast(msg, "error")
      }
    } catch {
      this._showToast("Network error. Please try again.", "error")
    } finally {
      this._setLoading(this.loginSubmitBtnTarget, this.loginSubmitLoaderTarget, false)
    }
  }

  // ── Toggle password visibility ───────────────────────────────

  togglePassword() {
    const input = this.pwdFieldTarget
    const hide  = input.type === "password"
    input.type  = hide ? "text" : "password"

    this.eyeIconTarget.innerHTML = hide
      ? `<path d="M1 9s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z"/><line x1="2" y1="2" x2="16" y2="16" stroke-linecap="round"/>`
      : `<path d="M1 9s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z"/><circle cx="9" cy="9" r="2.5"/>`
  }

  // ── OTP Login: send OTP ──────────────────────────────────────

  async sendLoginOtp() {
    const email = this.otpEmailFieldTarget.value.trim()

    if (!email || !this._validEmail(email)) {
      return this._showOtpEmailError("Please enter a valid email address")
    }

    this._hideTarget(this.otpEmailErrorTarget)
    this._setLoading(this.sendLoginOtpBtnTarget, this.sendLoginOtpLoaderTarget, true)

    try {
      const res  = await this._post(this.sendOtpUrlValue, { email })
      const data = await res.json()

      if (data.success) {
        this.loginOtpEmailDisplayTarget.textContent = email
        this._hideTarget(this.otpEmailStepTarget)
        this._showTarget(this.otpVerifyStepTarget)
        this._focusFirstOtpBox()
        this._startResendCountdown()
      } else {
        this._showOtpEmailError(data.message || "Email not found")
      }
    } catch {
      this._showOtpEmailError("Network error. Please try again.")
    } finally {
      this._setLoading(this.sendLoginOtpBtnTarget, this.sendLoginOtpLoaderTarget, false)
    }
  }

  _showOtpEmailError(msg) {
    this.otpEmailErrorTextTarget.textContent = msg
    this._showTarget(this.otpEmailErrorTarget)
  }

  backToOtpEmail() {
    this._showTarget(this.otpEmailStepTarget)
    this._hideTarget(this.otpVerifyStepTarget)
    this.otpBoxTargets.forEach(b => { b.value = ""; b.classList.remove("filled", "error") })
    this._hideTarget(this.loginOtpErrorTarget)
    if (this._countdownTimer) clearInterval(this._countdownTimer)
  }

  // ── OTP box input ────────────────────────────────────────────

  handleOtpInput(event) {
    const box   = event.currentTarget
    const index = parseInt(box.dataset.index)
    const val   = box.value.replace(/\D/g, "").slice(-1)
    box.value   = val

    box.classList.toggle("filled", val.length > 0)
    box.classList.remove("error")
    this._hideTarget(this.loginOtpErrorTarget)

    if (val && index < this.otpBoxTargets.length - 1) {
      this.otpBoxTargets[index + 1].focus()
    }
    if (this._getOtpValue().length === 6) this.verifyLoginOtp()
  }

  handleOtpKeydown(event) {
    const box   = event.currentTarget
    const index = parseInt(box.dataset.index)

    if (event.key === "Backspace" && !box.value && index > 0) {
      const prev = this.otpBoxTargets[index - 1]
      prev.value = ""
      prev.classList.remove("filled")
      prev.focus()
    }
    if (event.key === "ArrowLeft"  && index > 0)                             this.otpBoxTargets[index - 1].focus()
    if (event.key === "ArrowRight" && index < this.otpBoxTargets.length - 1) this.otpBoxTargets[index + 1].focus()
  }

  handleOtpPaste(event) {
    event.preventDefault()
    const pasted = (event.clipboardData || window.clipboardData)
      .getData("text").replace(/\D/g, "").slice(0, 6)

    pasted.split("").forEach((char, i) => {
      if (this.otpBoxTargets[i]) {
        this.otpBoxTargets[i].value = char
        this.otpBoxTargets[i].classList.add("filled")
      }
    })

    const nextEmpty = this.otpBoxTargets.find(b => !b.value)
    if (nextEmpty) nextEmpty.focus()
    else this.otpBoxTargets[5]?.focus()

    if (pasted.length === 6) this.verifyLoginOtp()
  }

  _getOtpValue() { return this.otpBoxTargets.map(b => b.value).join("") }
  _focusFirstOtpBox() { this.otpBoxTargets[0]?.focus() }

  // ── Verify OTP (login) ───────────────────────────────────────

  async verifyLoginOtp() {
    const otp   = this._getOtpValue()
    const email = this.otpEmailFieldTarget.value.trim()
    if (otp.length < 6) return

    this._setLoading(this.verifyLoginOtpBtnTarget, this.verifyLoginLoaderTarget, true)

    try {
      const res  = await this._post(this.verifyOtpUrlValue, { email, otp })
      const data = await res.json()

      if (data.success && data.redirect_url) {
        this._showToast("Signed in! Welcome back 🏏", "success")
        setTimeout(() => { window.location.href = data.redirect_url }, 700)
      } else {
        this._showLoginOtpError(data.message || "Invalid OTP")
        this.otpBoxTargets.forEach(b => b.classList.add("error"))
      }
    } catch {
      this._showLoginOtpError("Network error. Please try again.")
    } finally {
      this._setLoading(this.verifyLoginOtpBtnTarget, this.verifyLoginLoaderTarget, false)
    }
  }

  _showLoginOtpError(msg) {
    this.loginOtpErrorTextTarget.textContent = msg
    this._showTarget(this.loginOtpErrorTarget)
  }

  // ── Resend countdown ─────────────────────────────────────────

  resendLoginOtp() {
    this.otpBoxTargets.forEach(b => { b.value = ""; b.classList.remove("filled", "error") })
    this._hideTarget(this.loginOtpErrorTarget)
    this.sendLoginOtp()
  }

  _startResendCountdown(seconds = 30) {
    this._hideTarget(this.resendLoginBtnTarget)
    this._showTarget(this.loginCountdownTarget)
    const strong = this.loginCountdownTarget.querySelector("strong")
    strong.textContent = seconds

    let remaining = seconds
    this._countdownTimer = setInterval(() => {
      remaining--
      strong.textContent = remaining
      if (remaining <= 0) {
        clearInterval(this._countdownTimer)
        this._hideTarget(this.loginCountdownTarget)
        this._showTarget(this.resendLoginBtnTarget)
      }
    }, 1000)
  }

  // ── Helpers ──────────────────────────────────────────────────

  async _post(url, body) {
    return fetch(url, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this._csrfToken(),
        "Accept":       "application/json",
      },
      body: JSON.stringify(body),
    })
  }

  _csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  _validEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }

  _setLoading(btn, loaderEl, loading) {
    btn.disabled = loading
    const textEl = btn.querySelector(".btn-text")
    const arrow  = btn.querySelector(".btn-arrow")
    if (textEl) textEl.style.opacity = loading ? "0" : "1"
    if (arrow)  arrow.style.opacity  = loading ? "0" : "1"
    loaderEl.classList.toggle("hidden", !loading)
  }

  _showTarget(el) { el.classList.remove("hidden") }
  _hideTarget(el) { el.classList.add("hidden") }

  _showToast(message, type = "info") {
    document.querySelector(".spl-toast")?.remove()

    if (!document.getElementById("spl-toast-style")) {
      const s = document.createElement("style")
      s.id = "spl-toast-style"
      s.textContent = `@keyframes splToastIn{from{opacity:0;transform:translateX(-50%) translateY(12px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}`
      document.head.appendChild(s)
    }

    const colors = { error: "rgba(198,40,40,0.95)", success: "rgba(27,94,32,0.95)", info: "rgba(13,71,161,0.95)" }
    const toast  = document.createElement("div")
    toast.className   = "spl-toast"
    toast.textContent = message
    toast.style.cssText = `
      position:fixed;bottom:80px;left:50%;transform:translateX(-50%);
      background:${colors[type]||colors.info};color:#fff;
      padding:11px 22px;border-radius:24px;font-size:13px;
      font-family:Nunito,sans-serif;font-weight:600;z-index:9999;
      box-shadow:0 4px 20px rgba(0,0,0,0.45);white-space:nowrap;
      max-width:90vw;text-align:center;animation:splToastIn 0.25s ease;
    `
    document.body.appendChild(toast)
    setTimeout(() => toast.remove(), 3500)
  }
}
