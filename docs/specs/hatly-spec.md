# Hatly ("هاتلي") Specification Document

## 1. Goal & Context
- **Purpose**: **Hatly** ("هاتلي" - meaning "bring me" or "buy me" in Arabic) is a collaborative family shopping list app designed to streamline household requests. It replaces paper lists and scattered WhatsApp messages with a unified, real-time shared checklist.
- **Target Audience**: Families and households.
  - *Requesters (e.g., Mothers)* who manage household needs.
  - *Buyers (e.g., Fathers and Sons)* who fulfill the shopping requests.
- **Language Support**: Designed to natively support Arabic input for items and stores.

---

## 2. User Roles & Household Setup
- **Roles**:
  - **Admin / House Manager**: Can create/delete lists, invite members, manage subgroups, and view list progress in real-time.
  - **Fulfiller / Buyer**: Can view assigned lists, update list item statuses (Pending -> Bought / Out of Stock) in real-time.
- **Household Connection**:
  - A user creates a **Household Group** which generates a unique invitation code (e.g., `HAT-1234`).
  - Other family members join using this invitation code.
  - The Admin can organize members into custom subgroups (e.g., "Sons" subgroup, "Parents" subgroup) for easy list targeting.

---

## 3. Core Features
- **Household & Group Targeting**: Lists can be shared with the entire household, a specific subgroup (like "Sons"), or a specific individual member.
- **Hybrid Checklist Creator**:
  - *Quick Add*: Requesters type item names and hit enter to instantly add them to a list.
  - *WhatsApp Paste Import*: A text box where the user can paste a copy-pasted WhatsApp message. The app parses it line-by-line into checklist items.
- **Manual Item Categorization**:
  - When creating or editing items, users can quickly assign them to simple categories (e.g., 🛒 *Supermarket*, 💊 *Pharmacy*, 🍞 *Bakery*, 🥩 *Butcher*, ⚙️ *Other*).
  - Tapping a category icon next to the item name changes its category.
- **Live Real-time Shopping Checklist**:
  - Active checklists display items grouped by category so the shopper can navigate different sections of a store (or different stores) efficiently.
  - Real-time status toggle for each item:
    - **Pending** (Default)
    - **Bought** (Checked off, marked green, moves to the bottom)
    - **Out of Stock** (Marked red with an optional comment, e.g., "No Panadol Extra, bought normal instead")
  - Progress bar showing real-time updates (e.g., 3/7 items bought).
- **Push Notifications**:
  - Push notifications are sent to the targeted subgroup/member when a new list is assigned to them.
  - Real-time notification to the list creator when the shopper marks the list as "Completed" (items are on their way home).

---

## 4. App Screens & Navigation
1. **Welcome & Auth Screen**: Sign up and login via Email/Password or Phone.
2. **Household Setup Screen**:
   - Create a Household (generates code).
   - Join a Household (input code).
   - Admin panel to manage members and define subgroups (e.g. add specific members to the "Sons" group).
3. **Dashboard / Home Screen**:
   - *Admin View*: Active sent lists, progress indicators, "Create List" button, and completed history.
   - *Buyer View*: Active lists assigned to them or their group, sorted by date.
4. **Create / Edit List Screen**:
   - Fields: List Title/Store name, Destination Category (e.g., Supermarket), Target Recipients (dropdown).
   - Checklist creation area (Quick Add & Bulk Paste).
   - Manual category tags per item.
5. **Active Shopping Screen**:
   - Live checklists grouped by category (Supermarket items grouped together, Pharmacy items grouped together).
   - Item status toggles (Bought, Out of Stock).
   - Real-time progress bar.
   - "Finish Shopping" action button.

---

## 5. Technical Stack & Data Model
- **Frontend Framework**: Flutter (iOS, Android).
- **Backend Services**: Firebase.
  - **Firebase Auth**: User authentication.
  - **Firebase Cloud Messaging (FCM)**: Push notifications.
  - **Cloud Firestore**: Real-time NoSQL database.

### Firestore Data Schema

#### `users` Collection
```json
{
  "uid": "USER_ID",
  "name": "Ahmed",
  "email": "ahmed@example.com",
  "householdId": "HOUSEHOLD_ID",
  "fcmToken": "FCM_TOKEN_STRING"
}
```

#### `households` Collection
```json
{
  "id": "HOUSEHOLD_ID",
  "name": "Al-Sabah Family",
  "inviteCode": "HAT-1234",
  "adminId": "ADMIN_USER_ID",
  "createdAt": "TIMESTAMP",
  "subgroups": {
    "Sons": ["son_uid_1", "son_uid_2"],
    "Parents": ["admin_uid", "father_uid"]
  }
}
```

#### `shopping_lists` Collection
```json
{
  "id": "LIST_ID",
  "householdId": "HOUSEHOLD_ID",
  "title": "Weekly Needs",
  "createdBy": "ADMIN_USER_ID",
  "assignedTo": "Sons", // Can be a subgroup name or user_uid
  "status": "pending", // pending, active, completed
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP",
  "items": [
    {
      "id": "ITEM_1",
      "name": "حليب كامل الدسم",
      "category": "Supermarket",
      "status": "bought", // pending, bought, outOfStock
      "note": ""
    },
    {
      "id": "ITEM_2",
      "name": "بانادول",
      "category": "Pharmacy",
      "status": "outOfStock",
      "note": "Out of stock - bought alternate"
    }
  ]
}
```

---

## 6. Phased Implementation Plan
- **Phase 1: Setup & Firebase Integration**
  - Scaffold Flutter project directory structures.
  - Configure Firebase project and add configurations for Android/iOS.
  - Implement login, sign up, and household creation/joining flow.
- **Phase 2: Household & Subgroup Management**
  - Implement the admin dashboard for managing household members.
  - Add logic to define subgroups (e.g. "Sons") and associate user IDs.
- **Phase 3: List Creation & WhatsApp Import**
  - Build the creation screen with simple checklist input and WhatsApp paste parser.
  - Add manual category tagging per item.
- **Phase 4: Real-time Shopping & Checklist Updates**
  - Implement the active shopping view with real-time Firestore listeners.
  - Add Bought/Out-of-Stock toggling logic and group items visually by category.
- **Phase 5: Push Notifications & Polish**
  - Integrate FCM for push notifications when lists are assigned or completed.
  - Polish UI theme and Arabic RTL support.
