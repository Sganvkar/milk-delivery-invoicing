import { Router } from 'express'
import { verifySupabaseAuth } from '../middleware/authMiddleware'
import { fetchVendorInvoices, fetchInvoiceById, markInvoicePaid } from '../controllers/invoiceController'
import { ROUTES } from '../constants'

export const invoicesRouter = Router()

invoicesRouter.get(ROUTES.INVOICES_ROOT, verifySupabaseAuth, fetchVendorInvoices)
invoicesRouter.get(ROUTES.INVOICES_BY_ID, verifySupabaseAuth, fetchInvoiceById)
invoicesRouter.patch(ROUTES.INVOICES_MARK_PAID, verifySupabaseAuth, markInvoicePaid)
