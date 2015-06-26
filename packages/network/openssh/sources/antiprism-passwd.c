#include "includes.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <openssl/hmac.h>
#include <openssl/sha.h>
#include <openssl/err.h>

#include "packet.h"
#include "buffer.h"
#include "log.h"
// #include "servconf.h"
#include "key.h"
#include "hostfile.h"
#include "auth.h"
#include "auth-options.h"

#define KEY_BITS	(SHA512_DIGEST_LENGTH * 8)
#define KEY_BYTES	SHA512_DIGEST_LENGTH
#define HASHER	EVP_sha512()

#define MAX_PASSWORD_FILE_SIZE	(4 + 128 + 64)

extern char *config_file_name;
static const char *antiprism_password_path = "/storage/.cache/ssh/password";

/*void
set_antiprism_password_path(const char *new_path)
{
    antiprism_password_path = new_path;
}*/

int
sys_auth_passwd(Authctxt *authctxt, const char *password) 
{
    unsigned char password_buf[MAX_PASSWORD_FILE_SIZE];
    int h = open(antiprism_password_path, O_RDONLY);
    if (h < 0) {
        error("antiprism_password: cannot open password file");
        return 0;
    }
    int file_size;
    if ((file_size = read(h, password_buf, MAX_PASSWORD_FILE_SIZE)) <= 0) {
        close(h);
        error("antiprism_password: cannot read from password file");
        return 0;
    }
    close(h);
    if (file_size != MAX_PASSWORD_FILE_SIZE) {
        error("antiprism_password: bad password file");
        return 0;
    }
    uint32_t salt_size = *(int32_t *)&password_buf[0];
    if (salt_size != (unsigned)file_size - KEY_BYTES - sizeof salt_size) {
        error("antiprism_password: bad password file");
        return 0;
    }

    unsigned char *salt = password_buf + sizeof salt_size;
    unsigned char key_bytes[KEY_BYTES];
    if (PKCS5_PBKDF2_HMAC(password, strlen(password), salt, salt_size, 20000, HASHER, KEY_BYTES, key_bytes) != 1) {
        error("antiprism_password: PKCS5_PBKDF2_HMAC failed");
        return 0;
    }
    
    return (memcmp(key_bytes, salt + salt_size, KEY_BYTES) == 0);
}

