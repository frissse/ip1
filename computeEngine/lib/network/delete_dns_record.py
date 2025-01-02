import http.client
import ssl
import sys

ssl._create_default_https_context = ssl._create_unverified_context

conn = http.client.HTTPSConnection("api.cloudflare.com")

if __name__ == "__main__":
    x_auth_email = sys.argv[1]
    x_auth_key = sys.argv[2]
    zone_id = sys.argv[3]
    dns_record_id = sys.argv[4]
    content = sys.argv[5]
    name = sys.argv[6]

    headers = {
        'Content-Type': "application/json",
        'X-Auth-Email': x_auth_email,
        'X-Auth-Key': x_auth_key,
    }

    conn.request("DELETE", f"/client/v4/zones/{zone_id}/dns_records/{dns_record_id}", headers=headers)

    res = conn.getresponse()
    data = res.read()

    print(data.decode("utf-8"))