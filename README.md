# 🥛 Milk Delivery Invoice API

A backend API for managing daily milk deliveries, customers, and monthly invoices — built with **Node.js**, **TypeScript**, **Express**, and **Supabase**.

This API powers a vendor-facing dashboard that automates invoice generation, PDF creation, and payment tracking for local milk distributors.

---

## 🚀 Features

- **Vendor Authentication** — Supabase Auth with JWT-based verification  
- **Invoices Management**  
  - Fetch all invoices per vendor  
  - View detailed invoices with itemized milk records  
  - Mark invoices as paid / unpaid  
  - Generate invoice PDFs via Supabase Edge Functions  
- **Customer Management** (coming soon)  
  - Add, update, and list customers linked to a vendor  
- **Deliveries Management** (coming soon)  
  - Record daily milk deliveries  
  - Auto-generate monthly invoices  
- **RLS-secured data access** — Vendors can only access their own data  
- **Consistent API responses** using a shared response handler and constants

---

## 🧱 Tech Stack

| Layer | Technology |
|--------|-------------|
| **Language** | TypeScript |
| **Framework** | Express.js |
| **Database** | Supabase (PostgreSQL) |
| **Storage** | Supabase Storage (PDFs) |
| **Auth** | Supabase Auth (JWT) |
| **PDF Generation** | Supabase Edge Function + PDFKit |
| **Environment Management** | dotenv |

---

## 🗂️ Folder Structure

src/
├── app.ts # App entry point
├── constants/ # Shared constants (routes, messages, tables)
├── controllers/ # Handles requests/responses
├── routes/ # Express route definitions
├── services/ # Business logic (Supabase queries)
├── middleware/ # Auth middleware
├── utils/ # Helpers (supabase client, response handler)
└── ...
