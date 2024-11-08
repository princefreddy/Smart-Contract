// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DecentralizedLoan {
    struct Loan {
        address lender;
        uint amount;
        uint interestRate;
        uint deadline;
        bool loanPaid;
        bool active;
    }

    struct CollateralPerLoan{
        address borrower;
        uint loanIndex;
        uint collateralAmount;
    }

    Loan[] public loans;

    CollateralPerLoan[] public collaterals;

    // Afficher les garanties d'un prêt
    function collateralPerLoan(uint loanIndex) public view  returns (CollateralPerLoan memory) {
        return collaterals[loanIndex];
    }

    
   // Créer un prêt (prêteur)
    function createLoan(uint _loanAmount, uint _interestRate, uint _deadline) public payable {
        
        loans.push(Loan({
            lender: msg.sender,
            amount: _loanAmount,
            interestRate: _interestRate,
            deadline: _deadline,
            loanPaid: false,
            active: true
        }));
    }

    // Fonction permettant de récupérer tous les prêts disponibles
    function getAllLoans() public view returns (Loan[] memory) {
        return loans;
    }

    // L'emprunteur dépose une garantie
    function depositCollateral(uint loanIndex) public payable {
        require(loanIndex < loans.length, "Loan does not exist");
        require(loans[loanIndex].active, "Loan is no longer active");
        require(msg.sender != loans[loanIndex].lender, "Lender can't deposit collateral");
        require(msg.value >= loans[loanIndex].amount * 2, "Insufficient collateral");
        collaterals.push(CollateralPerLoan({
            borrower: msg.sender,
            loanIndex: loanIndex,
            collateralAmount: msg.value
        }));
    }

    // Le prêteur dépose le prêt
    function depositLoan(uint loanIndex) public payable {
        require(loanIndex < loans.length, "Loan does not exist");
        require(loans[loanIndex].active, "Loan is no longer active");
        require(msg.sender == loans[loanIndex].lender, "Only lender can deposit");
        require(msg.value == loans[loanIndex].amount, "Incorrect loan amount");

        // Rechercher le borrower pour lui transférer le montant
        for (uint i = 0; i < collaterals.length; i++) {
            if (collaterals[i].loanIndex == loanIndex && collaterals[i].borrower != address(0)) {
                
                // Transfert du montant au borrower
                address payable borrowerAddress = payable(collaterals[i].borrower);
                borrowerAddress.transfer(msg.value);

                break; 
            }
        }
    }

    // L'emprunteur rembourse le prêt avec les intérêts
    function repayLoan(uint loanIndex) public payable {
        require(loanIndex < loans.length, "Loan does not exist");
        require(loans[loanIndex].active, "Loan is no longer active");

        // Rechercher le borrower 
        for (uint i = 0; i < collaterals.length; i++) {
            if (collaterals[i].loanIndex == loanIndex && collaterals[i].borrower != address(0)) {
                
                // Vérification du borrower
                require(msg.sender == collaterals[loanIndex].borrower, "Only borrower can repay");

                // Montant à rembourser
                uint repaymentAmount = loans[loanIndex].amount + (loans[loanIndex].amount * loans[loanIndex].interestRate / 100);
                require(msg.value == repaymentAmount, "Incorrect repayment amount");
                payable(loans[loanIndex].lender).transfer(repaymentAmount);
                loans[loanIndex].loanPaid = true;
                payable(collaterals[loanIndex].borrower).transfer(collaterals[loanIndex].collateralAmount);  // Restitution de la garantie

                break; 
            }
        }
        
    }

    // Liquidation en cas de non-remboursement avant l'échéance
    function liquidate(uint loanIndex) public {
        require(block.timestamp > loans[loanIndex].deadline, "Loan not due yet");
        require(!loans[loanIndex].loanPaid, "Loan already repaid");

        // Rechercher le montant de la garantie
        for (uint i = 0; i < collaterals.length; i++) {
            if (collaterals[i].loanIndex == loanIndex) {
                // Le Lender récupère la garantie
                payable(loans[loanIndex].lender).transfer(collaterals[i].collateralAmount);

                break; 
            }
        }
        
    }
}