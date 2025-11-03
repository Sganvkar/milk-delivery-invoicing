import { Request, Response } from 'express'
import { getAllVendors, getVendorById } from '../services/vendorService'
import { MESSAGES, ERROR_CODES } from '../constants'

export async function fetchAllVendors(req: Request, res: Response) {
  try {
    const vendors = await getAllVendors()
    res.status(ERROR_CODES.SUCCESS).json(vendors)
  } catch (err: any) {
    console.error('Error fetching vendors:', err.message)
    res
      .status(ERROR_CODES.SERVER_ERROR)
      .json({ error: MESSAGES.FETCH_FAILED_VENDORS })
  }
}

export async function fetchCurrentVendor(req: any, res: Response) {
  try {
    const vendorId = req.user?.id
    if (!vendorId)
      return res.status(ERROR_CODES.UNAUTHORIZED).json({ error: MESSAGES.UNAUTHORIZED })

    const vendor = await getVendorById(vendorId)
    if (!vendor)
      return res.status(ERROR_CODES.NOT_FOUND).json({ error: MESSAGES.VENDOR_NOT_FOUND })

    res.status(ERROR_CODES.SUCCESS).json(vendor)
  } catch (err: any) {
    console.error('Error fetching current vendor:', err.message)
    res
      .status(ERROR_CODES.SERVER_ERROR)
      .json({ error: MESSAGES.FETCH_FAILED_VENDOR })
  }
}
