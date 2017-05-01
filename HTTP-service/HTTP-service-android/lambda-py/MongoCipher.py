def lambda_handler_xor_cipher(message, context):
    
    # AWS passes the HTTP request body as a dictionary to the first parameter
    msg = message.get("message")
    key = message.get("key")
    
    # IMPORTANT: 
    #   If the key length is less than the message, 
    #   zip() truncates the message to match the key length.
    
    if isinstance(msg, str):
        return "".join(chr(ord(a) ^ ord(b)) for a, b in zip(msg, key))
    else:
        # msg and key must be an iterable such as list or tuple
        return bytes([a ^ b for a, b in zip(msg, key)])