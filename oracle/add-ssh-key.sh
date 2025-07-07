#!/bin/bash
# Script to add new SSH key to Oracle Cloud instance
# Run this on the Oracle Cloud instance

# Add new SSH key to authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCldbvgVffftLDjTikLipdhSnUw0qbCke8uU9mj2feGvwI8KS/ecveejEIZwltEpb23OXChcaYBYf1mCFrUBX4zSGCuJ4V+ryt4IkYyhPXlMacne67fJGgiKJybYUet9uwjaeaYaft//fu14Lw1LBqDEm/TZ1jYyAahOeP+EN2W2BVp2e7NtSNvtNKRG1E4rPoE9/rMRmMslPNZ632hY1Vx1kKp/zVpKqDstE1dz7QEappfrVEOIh0/NnUvNCs9Y3euQXTRG3p3uePVWSo5vPO13xzAwgqqTtFJV0b8JdXWPw+3p42j5fzEXxd2vte67mPO8r4R5n/boCZYxWbBNxgih1MWdTfpNiGsnpJ/STO5abZL5mREEFzcHHXPA9eZ9+F+NX5Lx3NukhB7YBZr2Wc5nYFDtJWOeBtLDanY0Xvp43dXpxSrhDeXzCshqqNiznQ4tL5icKc+w/IQ9yNzNkU24ZQWTf3kzoEjsCmE+LnpoTDeutv1VZaQUiIjpAjjO9pfyvmYZCUG8bgwbFFlgs8/N6OtOcEeBtRh4P86gdZAxjFff/W/+NZcUB3uo+ctyyJ8HQR055XaIXkvzyfjENeuZGnUxgGvSSnephgqdM5KuzbjcAgkUMnLFFa9aDJeLX/YrkRZACplDLD7oWJYx48H3LMY30bHwUYNoiWIzYC2aw== neurosx@CorruptedAesthetic" >> ~/.ssh/authorized_keys

echo "✅ SSH key added successfully!"
echo "You can now connect from your local machine using:"
echo "ssh -i ~/.ssh/oracle_fennel_key ubuntu@150.136.84.41" 