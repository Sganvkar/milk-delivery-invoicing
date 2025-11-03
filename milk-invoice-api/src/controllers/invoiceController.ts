import { Request, Response } from 'express'
import { getInvoicesByVendorId, getInvoiceById, markInvoiceAsPaid } from '../services/invoiceService'
import { MESSAGES, ERROR_CODES } from '../constants'

export async function fetchVendorInvoices(req: any, res: Response) {
  try {
    const vendorId = req.user?.id
    if (!vendorId)
      return res.status(ERROR_CODES.UNAUTHORIZED).json({ error: MESSAGES.UNAUTHORIZED })

    const invoices = await getInvoicesByVendorId(vendorId)
    res.status(ERROR_CODES.SUCCESS).json(invoices)
  } catch (err: any) {
    console.error('Error fetching invoices:', err.message)
    res
      .status(ERROR_CODES.SERVER_ERROR)
      .json({ error: MESSAGES.FETCH_FAILED_INVOICES })
  }
}

export async function fetchInvoiceById(req: any, res: Response) {
  try {
    const vendorId = req.user?.id
    const invoiceId = req.params.id

    if (!vendorId)
      return res.status(ERROR_CODES.UNAUTHORIZED).json({ error: MESSAGES.UNAUTHORIZED })
    if (!invoiceId)
      return res.status(ERROR_CODES.BAD_REQUEST).json({ error: MESSAGES.MISSING_INVOICE_ID })

    const invoice = await getInvoiceById(vendorId, invoiceId)
    if (!invoice)
      return res.status(ERROR_CODES.NOT_FOUND).json({ error: MESSAGES.INVOICE_NOT_FOUND })

    res.status(ERROR_CODES.SUCCESS).json(invoice)
  } catch (err: any) {
    console.error('Error fetching invoice:', err.message)
    res
      .status(ERROR_CODES.SERVER_ERROR)
      .json({ error: MESSAGES.FETCH_FAILED_INVOICE })
  }
}

export async function markInvoicePaid(req: any, res: Response) {
  try {
    const vendorId = req.user?.id
    const invoiceId = req.params.id

    if (!vendorId)
      return res.status(ERROR_CODES.UNAUTHORIZED).json({ error: MESSAGES.UNAUTHORIZED })
    if (!invoiceId)
      return res.status(ERROR_CODES.BAD_REQUEST).json({ error: MESSAGES.MISSING_INVOICE_ID })

    const invoice = await markInvoiceAsPaid(vendorId, invoiceId)
    res.status(ERROR_CODES.SUCCESS).json(invoice)
  } catch (err: any) {
    console.error('Error marking invoice as paid:', err.message)
    res
      .status(ERROR_CODES.SERVER_ERROR)
      .json({ error: MESSAGES.UPDATE_FAILED_PAYMENT })
  }
}
