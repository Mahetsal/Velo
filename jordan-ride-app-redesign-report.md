# Jordan Ride App Redesign Benchmark (Executed)

## Objective Output

This brief executes the Jordan benchmark plan with primary sources first, then maps findings into a prioritized product direction.

Confidence tags used below:
- **Confirmed**: official pages, help centers, or official store listings
- **Probable**: consistent market pattern but not fully explicit in Jordan official docs
- **Unknown**: requires live in-app quote/cancellation tests

---

## Competitor Matrix (Jordan Scope)

| Area | Careem | Jeeny | Petra Ride | TaxiF |
|---|---|---|---|---|
| Jordan relevance | **Confirmed**: Jordan listed in service markets; Jordan-specific ride terms exist | **Confirmed**: listing says Saudi + Jordan; `Jeeny Economy` available in Jordan | **Confirmed**: Jordan-focused messaging + Jordan app listings | **Probable**: active regionally with Arabic help center/policies used in Jordan contexts |
| Booking flow | **Confirmed**: immediate or scheduled booking | **Confirmed**: simple tap-to-book messaging | **Confirmed**: app flow promoted as quick booking | **Confirmed**: destination + captain assignment flow in listing/help |
| Live trip tracking | **Confirmed**: real-time tracking | **Probable**: expected but not clearly documented in fetched official text | **Probable**: typical category behavior, not explicitly detailed | **Confirmed**: trip progress monitoring stated |
| Payments | **Confirmed**: cash, card, Apple Pay, Careem Pay credit | **Probable**: digital options implied; exact Jordan methods not clearly published | **Unknown**: no explicit public method list in fetched pages | **Confirmed**: cash and bank card policy documented |
| Pricing architecture | **Confirmed**: dynamic/high-demand increases, pre-authorization, cancellation fee possible | **Probable**: affordability focus + dynamic fluctuation indications, but no published formula | **Unknown**: no public component-level formula in fetched sources | **Confirmed**: estimate shown before booking in some cities; final price can recalc by time/distance/conditions |
| Tiering/service classes | **Confirmed**: Comfort, Executive, Max, Kids; Jordan terms mention Go/Go+ brands | **Confirmed**: Jordan has Economy; other tiers mostly KSA | **Confirmed**: taxi/private rides; broad Jordan coverage claims | **Probable**: standard taxi categories implied; no Jordan tier menu published |
| Safety/support signals | **Confirmed**: help center, account requirements, optional driver-side audio recording flow in terms | **Confirmed**: safety positioning + help center mention | **Confirmed**: licensed-driver positioning + 24/7 support number in listings | **Confirmed**: licensed/certified driver claims + help center + cancellation policy |

---

## Jordan Pricing Model Template (What Users See)

Use this as your product spec template for checkout transparency:

1. **Pre-book quote panel**
   - Estimated fare/range
   - ETA and service class
   - Explicit fee chips: surge/high-demand, toll, airport, service fee
2. **At-confirmation disclosures**
   - Cancellation fee trigger window
   - Waiting fee policy
   - Price-change conditions (route/time/traffic deviations)
3. **Payment selector**
   - Cash + digital methods
   - Fallback method behavior if digital charge fails
4. **Post-trip receipt**
   - Base + distance/time + surcharges + discounts
   - Reason codes for any difference vs estimate

Status against competitors:
- **Confirmed parity need**: cancellation transparency, dynamic pricing disclosure, cash+digital flexibility
- **Unknown in market**: exact per-km/per-minute coefficients by city/tier (all players)

---

## Redesign Recommendations

## Must-Have Parity (MVP)

1. 3-step request flow (pickup, dropoff, confirm)
2. Real-time map tracking + event timeline (accepted, arriving, started)
3. Price transparency stack: estimate, fee chips, cancellation/waiting policy
4. Cash + card + wallet-compatible payment
5. Safety and trust layer: driver identity card, trip share, in-trip help, fast support routing
6. Arabic-first Jordan UX with English fallback

## Differentiators For Jordan

1. **Pickup reliability UX**: landmark-first pickup in dense Amman zones
2. **Price confidence UI**: "why price changed" micro-explanations on receipt
3. **Trust dashboard**: visible driver verification and support SLA promise
4. **Local retention engine**: route-based rebook shortcuts (home/work/university/airport)

## Pricing/Tier Framework

- **Entry tier**: Economy (low-friction default)
- **Mid tier**: Comfort (quality uplift with bounded premium)
- **Premium tier**: XL/Executive-style option if supply supports it
- **Subscription layer (after reliability maturity)**:
  - Ride cashback/credits with monthly cap
  - Priority support
  - Optional cross-vertical perks only if ecosystem exists

---

## MVP vs Phase-2 Rollout

## MVP Now

- Economy + Comfort
- Full pre-book and post-trip price transparency
- Cash and digital payments
- Core safety controls and in-app support
- Localized Arabic-first IA

## Phase-2 After Metrics Stabilize

- Subscription pass
- Advanced safety flows (including optional audio-related policies where legal/operationally fit)
- Scheduled ride optimization / airport presets
- Family/corporate profiles

---

## Validation Gaps (Must Be Tested In-App)

These remain **Unknown** from public pages and should be captured through controlled quote sampling:
- Exact per-km/per-minute rates by city and tier
- Surge multipliers and trigger thresholds
- Cancellation fee thresholds and values per scenario
- Airport surcharge rules by city
- Cash vs digital final fare parity

Recommended sampling grid:
- Cities: `Amman`, `Irbid`, `Zarqa`
- Time blocks: AM peak, midday, PM peak, late night
- Routes: short urban, medium commute, airport

---

## Primary Sources Used

- Careem Jordan terms: <https://www.careem.com/en-AE/user-terms-jo-rides/>
- Careem rides page: <https://www.careem.com/en-AE/ride>
- Careem payment methods: <https://help.careem.com/hc/en-us/articles/4411603843219-Payment-methods>
- Jeeny Google Play: <https://play.google.com/store/apps/details?id=me.com.easytaxi>
- Jeeny App Store: <https://apps.apple.com/us/app/jeeny-book-affordable-rides/id1178701124>
- Petra Ride Google Play: <https://play.google.com/store/apps/details?id=com.PetraRide_User>
- Petra Ride App Store (Jordan): <https://apps.apple.com/jo/app/petra-ride/id1463809354>
- Petra Ride site: <https://www.petraride.com/users/>
- TaxiF Google Play: <https://play.google.com/store/apps/details?id=com.taxif.passenger>
- TaxiF cancellation policy: <https://taxif.com/en/cancellation-policy>
- TaxiF help (cancel reservation): <https://help.taxif.com/en/articles/92600-cancel-reservation>
- TaxiF help (fare calculation): <https://help.taxif.com/en/articles/92855-how-is-the-taxi-fare-calculated>
