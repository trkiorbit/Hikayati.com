# HIKAYATI AGENT MASTER SPEC

## 0) Purpose of this file
This file is the single source of truth for any agent, AI builder, or coding manager working on Hikayati.
It exists to prevent architectural drift, feature mixing, and random implementation.

Any agent reading this file must follow it as an execution contract, not as inspiration.
If any existing code conflicts with this file, this file wins unless an explicit newer decision document says otherwise.

---

## 1) Product definition
Hikayati is an AI storytelling platform for families.
The product transforms the child from a passive listener into the hero of a personalized story, then transforms the story into a cinematic visual/audio experience, then into saved memories and optionally into products sold via the in-app store.

Hikayati is NOT:
- only a story generator
- only a kids app
- only a cinema viewer
- only a store

Hikayati IS:
- a personalized story creation product
- a cinematic storytelling experience
- a library product
- a credits-based monetization product
- a store-enabled memory product
- a platform that can later expand into avatar, voice clone, video, education, and schools

---

## 2) Non-negotiable architectural laws
These rules are mandatory.

### LAW 1: UI does not generate stories
Flutter screens collect input, trigger actions, show loading states, and render output.
They must not own core orchestration logic.

### LAW 2: CinemaScreen is display-only
CinemaScreen must never contain story generation logic, image generation logic, avatar analysis logic, purchase logic, or persistence logic.
It only receives storyData and plays/displays it.

### LAW 3: Avatar is NOT part of the main story form layout logic
Avatar is an optional input source.
It is not the center of the Story Wizard.
It must not take over the create-story screen.
The agent must not redesign the Story Wizard around avatar.

### LAW 4: Avatar belongs to its own domain
Avatar setup/editing belongs in:
- Avatar Lab
- Account > Avatar Management
- optional picker inside Story Wizard

It does NOT belong as the dominant logic or dominant page content inside Story Wizard.

### LAW 5: Services are isolated
The following are separate services:
- text generation service
- image generation service
- normal TTS narration service
- voice cloning service
- avatar/vision analysis service
- payments service
- credits service

No agent may collapse them into one confusing mega-service.

### LAW 6: Public Library and Private Library are different domains
Public Library:
- discovery
- marketing
- featured stories
- free stories
- paid stories by credit
- seasonal content

Private Library:
- stories created by the user
- stories unlocked by the user
- stories purchased by the user
- saved story assets

### LAW 7: Store is a first-class feature, but not phase-one entrypoint
The store is core to the long-term business model.
However, the app must not open directly into the Store as the main first screen.
The first screen is Home.

### LAW 8: Build in phases
The agent must not implement all systems in one pass.
It must build by approved phases only.

### LAW 9: Child privacy is architectural
Do not design flows that permanently store sensitive child media by default.
Avatar is optional. Child voice cloning is forbidden. Parent voice cloning only.

### LAW 10: If unclear, preserve separation of concerns
When in doubt, keep logic outside screens and preserve modular boundaries.

---

## 3) Target system layers

### Layer A — Flutter Application Layer
Responsibilities:
- screens
- routing
- widgets
- user input forms
- media playback UI
- loading and error states
- localization UI

### Layer B — Story Engine / Application Orchestration Layer
Responsibilities:
- receives create-story request
- validates inputs
- decides whether to generate via AI or reuse existing content
- triggers text/image/audio services
- builds final storyData object
- triggers save/unlock/post-processing workflows

This is the real coordinator.

### Layer C — AI Services Layer
Independent services:
1. Text Generation Service
2. Image Generation Service
3. Narration TTS Service
4. Voice Clone Service
5. Avatar Vision Service

### Layer D — Backend Layer (Supabase)
Responsibilities:
- auth
- profiles
- credits balance
- stories storage
- public stories
- unlock records
- orders
- purchases
- storage buckets
- RPC / edge functions

---

## 4) Official feature phases
The agent must build only according to this roadmap.

### Phase 1 — Core Experience
Mandatory deliverables:
- Home screen
- Story Wizard screen
- Story Engine orchestration
- Text generation
- Image generation
- Cinema screen

Goal:
A user can create a personalized story and watch it in cinematic mode.

### Phase 2 — Real User + Persistence
Mandatory deliverables:
- authentication
- profile loading
- save story
- private library

Goal:
Created stories can be saved and replayed.

### Phase 3 — Public Library + Credits
Mandatory deliverables:
- public library
- free vs paid stories
- unlock flow
- deduct_credits RPC or equivalent secure backend action

Goal:
A user can unlock public stories using credits.

### Phase 4 — Settings + Policies + Standard Audio
Mandatory deliverables:
- settings screen
- app language
- story language
- sound/music preferences
- privacy policy page
- terms page
- standard narration playback

### Phase 5 — Store + Payments
Mandatory deliverables:
- store screen
- credit packages
- product catalog shell
- digital export shell
- payment integration
- order creation tracking

### Phase 6 — Advanced Personalization
Mandatory deliverables:
- avatar lab
- avatar management
- voice clone for parent only

### Phase 7 — Expansion
Optional later expansion:
- Hakim assistant
- video generation
- education mode
- schools mode

Important phase rule:
If the current project already has Cinema working, the next task is to stabilize the surrounding architecture and complete missing phase items, not to randomly jump to avatar or store dominance.

---

## 5) Screen map

### 5.1 HomeScreen
Purpose:
The main entrypoint of the app.

Contains:
- app branding/logo
- account access
- settings access
- language change
- featured public stories section
- create story primary CTA
- private library entry
- store entry
- policy links

Recommended top-to-bottom order:
1. top bar
2. hero banner
3. public stories preview
4. create story CTA
5. featured items / promotions
6. store teaser
7. account and policy links

### 5.2 StoryWizardScreen
Purpose:
Collect inputs needed to create a story.

Contains:
- child name
- child age
- story style
- image style
- narrator voice choice
- music on/off
- story language
- optional avatar selector
- visible credit cost
- generate button

Important:
Avatar is an optional section or selector.
It must not dominate the page.
It must not replace the normal story form.

Voice options:
- male narrator
- female narrator
- cloned parent voice (only if available)

Image style options:
- cartoon
- anime
- realistic
- avatar-assisted

Story style options:
- funny
- calm
- adventure
- educational
- exciting
- family

Music options:
- with music
- without music

### 5.3 CinemaScreen
Purpose:
Display the generated story as a cinematic experience.

Entry behavior:
After clicking Generate, user navigates to CinemaScreen immediately with loading/intro experience.

Cinema intro may include:
- dark background
- logo reveal
- short intro music
- opening phrase

Cinema elements:
- scene image
- scene text
- scene counter
- progress indicator
- next/previous if needed
- sound controls
- music controls
- close button
- save/open library CTA after completion

Strict rule:
CinemaScreen only displays storyData.

### 5.4 PublicLibraryScreen
Purpose:
Discovery, marketing, and credit-based unlocks.

Shows:
- free stories
- premium stories
- seasonal stories
- featured stories
- educational stories later

Behavior:
- free story -> open directly
- paid story -> confirm deduction then unlock
- bundled item -> open purchase or unlock path

### 5.5 PrivateLibraryScreen
Purpose:
The user’s owned stories.

Contains:
- created stories
- unlocked stories
- purchased stories
- product-related story records later

Behavior:
- tap -> open story
- if empty -> honest empty state, no fake placeholders
- sort/filter by date/language/type/source

### 5.6 AccountScreen
Contains:
- display name
- email
- credits balance
- number of stories
- purchases
- cloned voice management
- avatar management
- language
- logout

### 5.7 SettingsScreen
Contains:
- app language
- default story language
- sound preferences
- music toggle
- reading speed
- image quality
- notifications
- privacy
- terms
- delete account

### 5.8 StoreScreen
Purpose:
Monetization hub.

Sells:
- credits packages
- PDF/booklet export
- later printed booklet
- later t-shirt / poster / sticker / seasonal items

Important:
Store is core business, but it is not the dominant starting screen.

### 5.9 AvatarLabScreen
Purpose:
Manage avatar setup separately from story generation.

Contains:
- upload avatar source images
- analyze images via Avatar Vision Service
- produce editable visual descriptor
- save avatar profile to backend
- preview avatar profile data

This screen exists to STOP avatar logic from polluting StoryWizard.

---

## 6) Button map and navigation contract
This section exists because the agent is getting lost on where each button should lead.

### HomeScreen buttons
- "أنشئ قصة" -> navigate to StoryWizardScreen
- "المكتبة العامة" section card tap -> navigate to PublicLibraryScreen or open specific story
- "مكتبتي" -> navigate to PrivateLibraryScreen
- "المتجر" -> navigate to StoreScreen
- "الحساب" -> navigate to AccountScreen
- "الإعدادات" -> navigate to SettingsScreen
- "السياسة / الشروط" -> navigate to policy pages

### StoryWizardScreen buttons/actions
- narrator voice selector -> updates local form state only
- image style selector -> updates local form state only
- avatar picker -> opens Avatar Picker modal or AvatarLabScreen selection flow
- add another avatar -> opens additional avatar slot section, does not replace main form
- "توليد" ->
  1. validate form
  2. optionally pre-check credits if generation is paid
  3. create CreateStoryRequest
  4. navigate to CinemaScreen with loading state
  5. trigger StoryEngine orchestration

Important prohibition:
Clicking avatar controls must NOT reroute the user into a full avatar-first app experience unless the user explicitly enters Avatar Lab.

### CinemaScreen buttons/actions
- close X -> exit to HomeScreen or previous safe route
- save story -> call save story use case, then show success
- open library -> navigate to PrivateLibraryScreen
- replay -> restart cinema playback only
- next/previous -> scene navigation only
- sound toggle -> toggle narration only
- music toggle -> toggle background music only

Cinema buttons must not:
- regenerate the story directly
- re-run avatar analysis directly
- open payment flow unexpectedly

### PublicLibraryScreen buttons/actions
- open free story -> open viewer/cinema directly
- open paid story -> confirm credit deduction -> unlock -> add to user ownership -> open
- buy package -> navigate to StoreScreen

### PrivateLibraryScreen buttons/actions
- open story -> CinemaScreen or Story Details screen
- reorder/filter -> local state/query update only

### StoreScreen buttons/actions
- buy credits -> payment flow
- buy digital export -> order flow
- buy physical product -> order flow
- back -> HomeScreen or previous screen

### AccountScreen buttons/actions
- manage avatar -> AvatarLabScreen
- manage cloned voice -> Voice Profile management flow
- logout -> auth logout and return to auth/home

### AvatarLabScreen buttons/actions
- upload image -> media picker
- analyze -> AvatarVisionService
- edit descriptor -> local form editor
- save -> persist avatar profile to backend
- use in next story -> return selected avatar profile to StoryWizardScreen

---

## 7) Core domain entities

### CreateStoryRequest
Fields:
- childName
- childAge
- storyStyle
- imageStyle
- narratorVoiceMode
- storyLanguage
- musicEnabled
- avatarProfileIds optional
- additionalCharacters optional
- userId optional

### StoryData
Fields:
- storyId
- title
- summary
- language
- coverImageUrl
- audioMode
- musicEnabled
- scenes[]

### SceneData
Fields:
- sceneNumber
- text
- imagePrompt
- imageUrl
- audioUrl optional

### AvatarProfile
Fields:
- id
- ownerUserId
- displayName
- descriptorText
- styleHints
- referenceAssets optional
- createdAt

---

## 8) Backend data model
Supabase owns these domains.

### profiles
- user_id
- display_name
- credits_balance
- language
- settings_json
- cloned_voice_profile_id nullable
- avatar_profile_summary nullable

### stories
- id
- user_id
- title
- summary
- language
- scenes_json
- cover_image_url
- audio_mode
- source_type
- created_at

### public_stories
- id
- title
- summary
- cover_image_url
- category
- access_type
- price_credits
- scenes_json
- status

### unlocked_stories
- id
- user_id
- public_story_id
- credits_paid
- unlocked_at

### orders
- id
- user_id
- story_id nullable
- product_type
- amount
- payment_status
- order_status
- created_at

### credits_transactions
- id
- user_id
- amount
- type
- reason
- reference_id
- created_at

### avatar_profiles
- id
- user_id
- display_name
- descriptor_json or descriptor_text
- reference_assets_json
- created_at
- updated_at

---

## 9) Required backend actions
At minimum, support these use cases.

### deduct_credits(user_id, amount, reason)
Secure backend operation.
Never trust client-only deduction.

### unlock_public_story(user_id, story_id)
Must verify access type and balance.

### save_story_result(payload)
Stores story data and links it to the user.

### save_avatar_profile(payload)
Stores avatar descriptor/profile separately from story generation.

---

## 10) Agent implementation rules
The coding agent must obey these rules.

1. Do not move avatar to the center of StoryWizard.
2. Do not place avatar analysis logic inside CinemaScreen.
3. Do not make StoreScreen the app home.
4. Do not add payment SDK complexity before the approved payment phase unless explicitly requested.
5. Do not keep core AI orchestration inside widget code.
6. Do not mix normal narration with voice cloning in one unclear service.
7. Do not fake library data when the library is empty.
8. Do not create hidden navigation routes with no map in this file.
9. Do not change screen responsibilities without updating this document.
10. If a feature seems related to avatar, first ask: does this belong to AvatarLab or only as an optional picker in StoryWizard?

---

## 11) Current project status assumptions
Based on existing progress, the project already reached a point where a cinematic story can be shown inside CinemaScreen.
This means:
- Cinema is already conceptually proven
- The problem is now architecture drift and unclear plan
- The agent must stop improvising and align with this master spec

Therefore, current priority is NOT “invent new product direction”.
Current priority IS:
- stabilize architecture
- finish missing phase boundaries
- restore screen responsibilities
- keep avatar modular and optional

---

## 12) Immediate correction plan for the current codebase
If the current codebase is confused, apply this order:

### Step 1
Confirm routes and screen ownership:
- Home
- StoryWizard
- Cinema
- PrivateLibrary
- PublicLibrary
- Store
- Account
- Settings
- AvatarLab

### Step 2
Refactor CinemaScreen so it only consumes StoryData.

### Step 3
Refactor StoryWizard so avatar is a small optional section, not the whole page.

### Step 4
Extract orchestration into StoryEngine / use case layer.

### Step 5
Keep AvatarVisionService separate and only called from AvatarLab or optional avatar selection flow.

### Step 6
Stabilize save flow and private library.

### Step 7
Only after that, implement public library + credits.

---

## 13) Suggested folder structure

lib/
  core/
    constants/
    theme/
    routes/
    utils/
  features/
    home/
    story_wizard/
    cinema/
    public_library/
    private_library/
    store/
    account/
    settings/
    auth/
    avatar_lab/
  application/
    story_engine/
    use_cases/
  services/
    ai_text/
    ai_image/
    ai_tts/
    ai_voice_clone/
    avatar_vision/
    payments/
    credits/
  data/
    models/
    repositories/
    datasources/
  backend/
    supabase/

---

## 14) Acceptance criteria for each major screen

### HomeScreen done when:
- it is the default entrypoint after auth/main routing
- create story button works
- store entry works
- library entries work
- there is no broken dead-end button

### StoryWizard done when:
- user can enter core story fields
- avatar is optional and not dominant
- generate button triggers story creation flow
- user transitions to cinema flow properly

### CinemaScreen done when:
- it renders received storyData only
- it can show scene image/text progression
- it does not own generation logic

### AvatarLab done when:
- user can upload source image(s)
- agent can analyze and save avatar profile
- avatar can later be selected from StoryWizard

### Store done when:
- it shows credit packages and/or product cards
- navigation works
- payment flow is phase-appropriate

---

## 15) Definition of done for the stable MVP baseline
The stable MVP baseline is complete when all of these are true:
- user lands on Home, not Store
- user can open StoryWizard
- user can generate a personalized story
- user is taken into Cinema flow
- Cinema displays story content correctly
- story can be saved
- saved stories appear in Private Library
- architecture keeps avatar optional and modular
- no screen owns another screen’s business logic

---

## 16) Final instruction to the agent manager
Do not improvise product structure.
Do not redistribute responsibilities arbitrarily.
Do not let AvatarLab consume StoryWizard.
Do not let Cinema become an engine.
Do not let Store become Home.

Build according to this file exactly.
When uncertain, preserve separation of concerns and phase order.

