Class AES
{
    Encrypt(string, password, alg)
    {
        len := this.StrPutVar(string, str_buf, 0, "UTF-16")
        this.Crypt(str_buf, len, password, alg, 1)
        return this.b64Encode(str_buf, len)
    }
    Decrypt(string, password, alg)
    {
        len := this.b64Decode(string, encr_Buf)
        sLen := this.Crypt(encr_Buf, len, password, alg, 0)
        sLen /= 2
        return StrGet(&encr_Buf, sLen, "UTF-16")
    }

    Crypt(ByRef encr_Buf, ByRef Buf_Len, password, ALG_ID, CryptMode := 1)
    {
        ; WinCrypt.h
        static MS_ENH_RSA_AES_PROV := "Microsoft Enhanced RSA and AES Cryptographic Provider"
        static PROV_RSA_AES        := 24
        static CRYPT_VERIFYCONTEXT := 0xF0000000
        static CALG_SHA1           := 0x00008004
        static CALG_SHA_256        := 0x0000800c
        static CALG_SHA_384        := 0x0000800d
        static CALG_SHA_512        := 0x0000800e
        static CALG_AES_128        := 0x0000660e ; KEY_LENGHT := 0x80  ; (128)
        static CALG_AES_192        := 0x0000660f ; KEY_LENGHT := 0xC0  ; (192)
        static CALG_AES_256        := 0x00006610 ; KEY_LENGHT := 0x100 ; (256)
        static KP_BLOCKLEN         := 8

        if !(DllCall("advapi32.dll\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "Uint", PROV_RSA_AES, "UInt", CRYPT_VERIFYCONTEXT))
            MsgBox % "*CryptAcquireContext (" DllCall("kernel32.dll\GetLastError") ")"

        if !(DllCall("advapi32.dll\CryptCreateHash", "Ptr", hProv, "Uint", CALG_SHA1, "Ptr", 0, "Uint", 0, "Ptr*", hHash))
            MsgBox % "*CryptCreateHash (" DllCall("kernel32.dll\GetLastError") ")"

        passLen := this.StrPutVar(password, passBuf, 0, "UTF-16")
        if !(DllCall("advapi32.dll\CryptHashData", "Ptr", hHash, "Ptr", &passBuf, "Uint", passLen, "Uint", 0))
            MsgBox % "*CryptHashData (" DllCall("kernel32.dll\GetLastError") ")"
        
        if !(DllCall("advapi32.dll\CryptDeriveKey", "Ptr", hProv, "Uint", CALG_AES_%ALG_ID%, "Ptr", hHash, "Uint", (ALG_ID << 0x10), "Ptr*", hKey)) ; KEY_LENGHT << 0x10
            MsgBox % "*CryptDeriveKey (" DllCall("kernel32.dll\GetLastError") ")"

        if !(DllCall("advapi32.dll\CryptGetKeyParam", "Ptr", hKey, "Uint", KP_BLOCKLEN, "Uint*", BlockLen, "Uint*", 4, "Uint", 0))
            MsgBox % "*CryptGetKeyParam (" DllCall("kernel32.dll\GetLastError") ")"
        BlockLen /= 8

        if (CryptMode)
            DllCall("advapi32.dll\CryptEncrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len, "Uint", Buf_Len + BlockLen)
        else
            DllCall("advapi32.dll\CryptDecrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len)

        DllCall("advapi32.dll\CryptDestroyKey", "Ptr", hKey)
        DllCall("advapi32.dll\CryptDestroyHash", "Ptr", hHash)
        DllCall("advapi32.dll\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        return Buf_Len
    }

    StrPutVar(string, ByRef var, addBufLen := 0, encoding := "UTF-16")
    {
        tlen := ((encoding = "UTF-16" || encoding = "CP1200") ? 2 : 1)
        str_len := StrPut(string, encoding) * tlen
        VarSetCapacity(var, str_len + addBufLen, 0)
        StrPut(string, &var, encoding)
        return str_len - tlen
    }

    b64Encode(ByRef VarIn, SizeIn)
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CRYPT_STRING_NOCRLF := 0x40000000
        DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", SizeOut)
        VarSetCapacity(VarOut, SizeOut, 0)
        DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", &VarOut, "UInt*", SizeOut)
        return StrGet(&VarOut, SizeOut, "CP0")
    }
    b64Decode(ByRef VarIn, ByRef VarOut)
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CryptStringToBinary := "CryptStringToBinary" (A_IsUnicode ? "W" : "A")
        DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
        VarSetCapacity(VarOut, SizeOut, 0)
        DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", &VarOut, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
        return SizeOut
    }
}



