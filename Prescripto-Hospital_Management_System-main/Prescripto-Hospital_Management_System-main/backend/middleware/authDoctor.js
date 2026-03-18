import jwt from 'jsonwebtoken'

// doctor authentication middleware
const authDoctor = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        
        // Check if authorization header exists and starts with 'Bearer'
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.json({ success: false, message: 'Not Authorized Login Again' })
        }
        
        const token = authHeader.substring(7); // Remove 'Bearer ' prefix
        
        const token_decode = jwt.verify(token, process.env.JWT_SECRET)
        
        // Attach the doctor ID to the request body so controllers can use it
        req.body.docId = token_decode.id
        
        next()

    } catch (error) {
        console.log(error)
        res.json({ success: false, message: error.message })
    }
}

export default authDoctor;