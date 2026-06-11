// app/javascript/controllers/spl_registration_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step", "stepDot", "stepLine",
    "nameField", "emailField",
    "sendOtpBtn", "sendOtpLoader",
    "otpBox", "otpEmailDisplay",
    "verifyOtpBtn", "verifyLoader",
    "otpError", "otpErrorText",
    "resendBtn", "countdown",
    "hiddenName", "hiddenEmail",
    "registrationForm",
    "submitBtn", "submitLoader",
    "passwordField", "confirmPasswordField", "eyeIcon",
    "strengthFill", "strengthLabel",
  ]

  static values = {
    sendOtpUrl:   String,
    verifyOtpUrl: String,
  }

  connect() {
    this.currentStep = 1
    this._countdownTimer = null
  }

  disconnect() {
    if (this._countdownTimer) clearInterval(this._countdownTimer)
  }

  // ── Step navigation ──────────────────────────────────────────

  goToStep(n) {
    this.stepTargets.forEach(el => {
      const idx = parseInt(el.dataset.stepIndex)
      el.classList.toggle("active", idx === n)
    })
    this.stepDotTargets.forEach(dot => {
      const step = parseInt(dot.dataset.step)
      dot.classList.toggle("active", step === n)
      dot.classList.toggle("done",   step < n)
    })
    this.stepLineTargets.forEach((line, i) => {
      line.classList.toggle("done", i + 1 < n)
    })
    this.currentStep = n
  }

  goBack() {
    if (this.currentStep > 1) this.goToStep(this.currentStep - 1)
  }

  // ── Send OTP ─────────────────────────────────────────────────

  async sendOtp() {
    const name  = this.nameFieldTarget.value.trim()
    const email = this.emailFieldTarget.value.trim()

    if (!name)                          return this._shake(this.nameFieldTarget,  "Please enter your name")
    if (!email || !this._validEmail(email)) return this._shake(this.emailFieldTarget, "Please enter a valid email")

    this._setLoading(this.sendOtpBtnTarget, this.sendOtpLoaderTarget, true)

    try {
      const res  = await this._post(this.sendOtpUrlValue, { email, name })
      const data = await res.json()

      if (data.success) {
        this.otpEmailDisplayTarget.textContent = email
        this.goToStep(2)
        this._focusFirstOtpBox()
        this._startResendCountdown()
      } else {
        this._showToast(data.message || "Failed to send OTP", "error")
      }
    } catch {
      this._showToast("Network error. Please try again.", "error")
    } finally {
      this._setLoading(this.sendOtpBtnTarget, this.sendOtpLoaderTarget, false)
    }
  }

  // ── OTP input handling ───────────────────────────────────────

  handleOtpInput(event) {
    const box   = event.currentTarget
    const index = parseInt(box.dataset.index)
    const val   = box.value.replace(/\D/g, "").slice(-1)
    box.value   = val

    box.classList.toggle("filled", val.length > 0)
    box.classList.remove("error")
    this._hideTarget(this.otpErrorTarget)

    if (val && index < this.otpBoxTargets.length - 1) {
      this.otpBoxTargets[index + 1].focus()
    }
    if (this._getOtpValue().length === 6) this.verifyOtp()
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

    if (pasted.length === 6) this.verifyOtp()
  }

  _getOtpValue() { return this.otpBoxTargets.map(b => b.value).join("") }
  _focusFirstOtpBox() { this.otpBoxTargets[0]?.focus() }

  // ── Verify OTP ───────────────────────────────────────────────

  async verifyOtp() {
    const otp   = this._getOtpValue()
    const email = this.emailFieldTarget.value.trim()
    if (otp.length < 6) return

    this._setLoading(this.verifyOtpBtnTarget, this.verifyLoaderTarget, true)

    try {
      const res  = await this._post(this.verifyOtpUrlValue, { email, otp })
      const data = await res.json()

      if (data.success) {
        if (this._countdownTimer) clearInterval(this._countdownTimer)
        this.hiddenNameTarget.value  = this.nameFieldTarget.value.trim()
        this.hiddenEmailTarget.value = email
        this.goToStep(3)
      } else {
        this._showOtpError(data.message || "Invalid OTP")
        this.otpBoxTargets.forEach(b => b.classList.add("error"))
      }
    } catch {
      this._showOtpError("Network error. Please try again.")
    } finally {
      this._setLoading(this.verifyOtpBtnTarget, this.verifyLoaderTarget, false)
    }
  }

  _showOtpError(msg) {
    this.otpErrorTextTarget.textContent = msg
    this._showTarget(this.otpErrorTarget)
  }

  // ── Resend countdown ─────────────────────────────────────────

  resendOtp() {
    this.otpBoxTargets.forEach(b => { b.value = ""; b.classList.remove("filled", "error") })
    this._hideTarget(this.otpErrorTarget)
    this.sendOtp()
  }

  _startResendCountdown(seconds = 30) {
    this._hideTarget(this.resendBtnTarget)
    this._showTarget(this.countdownTarget)
    const strong = this.countdownTarget.querySelector("strong")
    strong.textContent = seconds

    let remaining = seconds
    this._countdownTimer = setInterval(() => {
      remaining--
      strong.textContent = remaining
      if (remaining <= 0) {
        clearInterval(this._countdownTimer)
        this._hideTarget(this.countdownTarget)
        this._showTarget(this.resendBtnTarget)
      }
    }, 1000)
  }

  // ── Submit registration via fetch (Step 3) ───────────────────
  //
  // THE KEY FIX: Your controller's `create` action returns JSON,
  // but a plain <form> submit causes a full-page navigation so the
  // JSON renders raw in the browser.  We intercept `submit`,
  // POST via fetch, and handle success/error in JS instead.

  async submitRegistration(event) {
    event.preventDefault()

    const password = this.passwordFieldTarget.value
    const confirm  = this.confirmPasswordFieldTarget.value

    // Catch mismatches client-side before even hitting the server
    if (!password) {
      return this._showToast("Please enter a password", "error")
    }
    if (password !== confirm) {
      return this._showToast("Password confirmation doesn't match Password", "error")
    }
    if (password.length < 8) {
      return this._showToast("Password must be at least 8 characters", "error")
    }

    this._setLoading(this.submitBtnTarget, this.submitLoaderTarget, true)

    try {
      const form     = this.registrationFormTarget
      const formData = new FormData(form)

      const res = await fetch(form.action, {
        method:  "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept":       "application/json",
        },
        body: formData,
      })

      const data = await res.json()

      if (data.success) {
        this._showToast("Account created! Welcome to SPL Fantasy 🏏", "success")
        setTimeout(() => { window.location.href = data.redirect_url || "/" }, 900)
      } else {
        // Show whatever Devise / the controller returns as message
        const msg = data.message
          || (Array.isArray(data.errors) ? data.errors[0] : null)
          || "Registration failed. Please try again."
        this._showToast(msg, "error")
      }
    } catch {
      this._showToast("Network error. Please try again.", "error")
    } finally {
      this._setLoading(this.submitBtnTarget, this.submitLoaderTarget, false)
    }
  }

  // ── Password strength ────────────────────────────────────────

  checkPasswordStrength() {
    const pw = this.passwordFieldTarget.value
    let score = 0
    if (pw.length >= 8)           score++
    if (/[A-Z]/.test(pw))         score++
    if (/[0-9]/.test(pw))         score++
    if (/[^A-Za-z0-9]/.test(pw))  score++

    const levels = [
      { pct: "0%",   color: "transparent", label: "",       labelColor: "" },
      { pct: "25%",  color: "#ef5350",     label: "Weak",   labelColor: "#ef9a9a" },
      { pct: "50%",  color: "#ffa726",     label: "Fair",   labelColor: "#ffcc80" },
      { pct: "75%",  color: "#fdd835",     label: "Good",   labelColor: "#fff176" },
      { pct: "100%", color: "#43a047",     label: "Strong", labelColor: "#a5d6a7" },
    ]
    const lvl = pw.length === 0 ? levels[0] : (levels[score] || levels[1])
    this.strengthFillTarget.style.width      = lvl.pct
    this.strengthFillTarget.style.background = lvl.color
    this.strengthLabelTarget.textContent     = lvl.label
    this.strengthLabelTarget.style.color     = lvl.labelColor
  }

  // ── Toggle password visibility ───────────────────────────────

  togglePassword() {
    const input = this.passwordFieldTarget
    const hide  = input.type === "password"
    input.type  = hide ? "text" : "password"

    this.eyeIconTarget.innerHTML = hide
      ? `<path d="M1 9s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z"/><line x1="2" y1="2" x2="16" y2="16" stroke-linecap="round"/>`
      : `<path d="M1 9s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z"/><circle cx="9" cy="9" r="2.5"/>`
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

  _shake(inputEl, message) {
    inputEl.classList.add("error")
    inputEl.focus()
    setTimeout(() => inputEl.classList.remove("error"), 500)
    this._showToast(message, "error")
  }

  _showToast(message, type = "info") {
    document.querySelector(".spl-toast")?.remove()

    // Inject keyframe once
    if (!document.getElementById("spl-toast-style")) {
      const s = document.createElement("style")
      s.id = "spl-toast-style"
      s.textContent = `@keyframes splToastIn{from{opacity:0;transform:translateX(-50%) translateY(12px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}`
      document.head.appendChild(s)
    }

    const colors = { error: "rgba(198,40,40,0.95)", success: "rgba(27,94,32,0.95)", info: "rgba(13,71,161,0.95)" }
    const toast  = document.createElement("div")
    toast.className  = "spl-toast"
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