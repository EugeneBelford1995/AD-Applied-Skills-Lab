# AD-Applied-Skills-Lab
Setup the lab outlined in Microsoft Learn's APL-1008 course

Spins up the VMs, creates the domain, OUs, users, groups, site, etc described in the lab at the end of APL-1008, as well as creating the site, delegation of rights, everything except the GPOs.

Put them in the same folder, grab a Windows Server 2022 ISO from the Microsoft Evaluation Center, save it in a folder called ISOs, and run Create-Lab.ps1.
Change the variable $ISOPath if you save the ISO somewhere different!

It takes 20 - 30 mintues to create everything due to restarts, waiting on the 2 DCs to sync, etc.

The remaining steps in Microsoft's lab are completed in ADAC and GPMC. Login as Administrator \ Pa55w.rdPa55w.rd and set the following:

--- Default Domain Policy ---

Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy

Set the min pwd length = 14

--- FGPP ---

Set a FGPP named Domain Admins Password Policy
Make Domain Admins have a min pwd length = 16


--- Default Domain Controller Policy ---

Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

Network security: Restrict NTLM: NTLM authentication in this domain

Define this policy setting
Deny all accounts
Ok
Yes


--- SydneyOUPolicy ---

Create a GPO & link it to the Sydney OU

Configuration\Policies\Windows Settings\Security Settings\Advanced Audit Policy Configuration\Audit Policies\Account Management

Audit User account management
Configure the following audit events
Success & Failure 
Ok


Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\User Rights Assignment

Deny Log on as a service
Define this policy
Add User or Group
Sydney Administrators
Ok

--- Summary ---

Import Cleanup.ps1 and 'Cleanup-VM -VMName <name>' to stop the VMs, remove them from Hyper-V, and delete their files once you're done with the lab. Don't run Cleanup.ps1 unless and until then!

Good luck on your assessment! Please leave any comments, suggestions, criticisms, etc here or on our Medium. Feedback is welcome!
