import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { vendorsRouter } from './routes/vendors'
import { invoicesRouter } from './routes/invoices'
import { ROUTES, MESSAGES } from './constants'

dotenv.config()

const app = express()
app.use(cors())
app.use(express.json())

app.use(ROUTES.VENDORS, vendorsRouter)
app.use(ROUTES.INVOICES, invoicesRouter)

app.get('/', (_, res) => res.send(MESSAGES.API_RUNNING))

const PORT = process.env.PORT || 4000
app.listen(PORT, () => console.log(`${MESSAGES.SERVER_RUNNING} ${PORT}`))