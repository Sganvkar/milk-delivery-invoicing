import { Router } from 'express'
import { fetchAllVendors, fetchCurrentVendor } from '../controllers/vendorController'
import { verifySupabaseAuth } from '../middleware/authMiddleware'
import { ROUTES } from '../constants'

export const vendorsRouter = Router()

// /api/vendors
vendorsRouter.get(ROUTES.VENDORS_ROOT, fetchAllVendors)

// /api/vendors/me
vendorsRouter.get(ROUTES.VENDORS_ME, verifySupabaseAuth, fetchCurrentVendor)
