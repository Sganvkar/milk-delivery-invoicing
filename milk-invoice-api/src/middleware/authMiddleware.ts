import { Request, Response, NextFunction } from 'express'
import { supabase } from '../utils/supabaseClient'
import { MESSAGES, ERROR_CODES } from '../constants'

export async function verifySupabaseAuth(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(ERROR_CODES.UNAUTHORIZED).json({
        error: MESSAGES.MISSING_AUTH_HEADER,
      })
    }

    const token = authHeader.split(' ')[1]

    const { data, error } = await supabase.auth.getUser(token)
    if (error || !data?.user) {
      console.error('Auth verification failed:', {
        message: error?.message,
        status: error?.status,
        name: error?.name,
      })

      return res.status(ERROR_CODES.UNAUTHORIZED).json({
        error: MESSAGES.UNAUTHORIZED,
        message: error?.message || MESSAGES.NO_USER_DATA,
      })
    }

    // Attach user info to request
    (req as any).user = { id: data.user.id, email: data.user.email }
    next()
  } catch (err: any) {
    console.error('Auth middleware error:', err.message)
    res.status(ERROR_CODES.SERVER_ERROR).json({
      error: MESSAGES.AUTH_CHECK_FAILED,
    })
  }
}
