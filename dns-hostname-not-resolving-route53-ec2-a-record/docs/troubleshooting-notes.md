# Troubleshooting Notes (fill this during your run)

## Symptoms
- [ ] NXDOMAIN
- [ ] SERVFAIL
- [ ] Resolves on some resolvers only
- [ ] Wrong IP returned

## What I checked
- Hosted zone exists in Route 53: ✅/❌
- Registrar NS matches Route 53 NS: ✅/❌
- A record exists for apex: ✅/❌
- A record exists for www (optional): ✅/❌
- Multi-resolver results consistent: ✅/❌
- Authoritative NS returns correct record: ✅/❌

## Evidence (paste outputs)
### NS records
```bash
dig NS lilianebooks.online +short
Resolver checks
dig @8.8.8.8 lilianebooks.online A +noall +answer
dig @1.1.1.1 lilianebooks.online A +noall +answer
dig @9.9.9.9 lilianebooks.online A +noall +answer
Authoritative check
dig @<one-route53-ns> lilianebooks.online A +noall +answer
Trace
dig lilianebooks.online +trace
Final fix applied
 Updated registrar nameservers

 Created/updated Route 53 A record

 Lowered TTL to 60

 Removed conflicting record types (A vs CNAME)

Final verification
dig lilianebooks.online A +short returns the expected EC2 IP ✅
