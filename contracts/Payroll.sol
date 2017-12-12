pragma solidity ^0.4.18;

import "./PayrollInterface.sol";
import "./date/DateTime.sol";
import "./Owned.sol";
import "./token/EURToken.sol";

contract Payroll is EURToken, Owned, DateTime, PayrollInterface {

    //EVENTS
    event NewEmployee(uint256 employeeId, address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary);
    event NewToken(uint256 tokenId, address tokenAddress, uint256 EURRate);
    event DeleteEmployee();
    event UpdateSalary();

    //PROPERTY
    struct Employee {
        uint256 employeedId;
        address accountAddress;
        address[] allowedToken;
        uint256[] tokenDistribution;
        uint256 yearlyEURSalary;
        uint lastPayCheck;
        uint lastDistributionDay;
    }

    address[] private employeeIndex;
    mapping(address => Employee) private m_employees;

    struct Token {
        uint256 tokenId;
        address token;
        uint256 EURExchangeRate;
    }

    address[] private tokenIndex;
    mapping(address => Token) private m_token;

    address oracle;

    uint256 internal updatedTotalYearlySalary = 0;

    //MODIFIER
    modifier onlyEmployee(){
        if (!(m_employees[msg.sender].accountAddress == msg.sender)) {
            revert();
        }
        _;
    }

    modifier onlyOracle(){
        if (!(oracle == msg.sender)) {
            revert();
        }
        _;
    }

    //CONSTRUTOR
    function Payroll(address _oracle) public {
        oracle = _oracle;
    }

    //FUNCTIONS
    //INTERNAL
    function insertToken(address newTokenAddress, uint256 EURExchangeRate) internal {
        require(newTokenAddress != address(0) && EURExchangeRate >= 0);

        if (!tokenExist(newTokenAddress)) {
            var newToken = Token(tokenIndex.length, newTokenAddress, EURExchangeRate);
            m_token[newTokenAddress] = newToken;
            tokenIndex.push(newTokenAddress);

            NewToken(newToken.tokenId, newToken.token, newToken.EURExchangeRate);
        }
    }

    //ONLY OWNER
    function addEmployee(address accountAddress, address[] allowedTokens, uint256[] tokenDistribution, uint256 initialYearlyEURSalary) onlyOwner public {
        require(accountAddress != address(0) && allowedTokens.length > 0 && initialYearlyEURSalary > 0);
        require(allowedTokens.length == tokenDistribution.length);

        if (!employeeExist(accountAddress)) {
            var newEmployee = Employee(employeeIndex.length, accountAddress, allowedTokens, tokenDistribution, initialYearlyEURSalary, now, now);

            NewEmployee(employeeIndex.length, accountAddress, allowedTokens, initialYearlyEURSalary);
            m_employees[accountAddress] = newEmployee;

            updateTotalSalary(initialYearlyEURSalary, 0);
            employeeIndex.push(accountAddress);

            for (uint i = 0; i < allowedTokens.length; i++) {
                if (!(tokenExist(allowedTokens[i]))) {
                    insertToken(allowedTokens[i], 0);
                }
            }
        }
    }

    function setEmployeeSalary(uint256 employeeId, uint256 newSalary) onlyOwner public {
        address employeddAddress = getEmployeeById(employeeId);
        if (employeeExist(employeddAddress)) {
            
            updateTotalSalary(newSalary,  m_employees[employeddAddress].yearlyEURSalary);

            m_employees[employeddAddress].yearlyEURSalary = newSalary;
        }
    }

    function removeEmployee(uint256 employeeId) onlyOwner public {
        address employeeToDelete = getEmployeeById(employeeId);

        if (employeeExist(employeeToDelete)) {
            var employeeToMove = employeeIndex[employeeIndex.length - 1];

            employeeIndex[employeeId] = employeeToMove;

            updateTotalSalary(0,  m_employees[employeeToDelete].yearlyEURSalary);

            m_employees[employeeToMove].employeedId = employeeId;
            employeeIndex.length--;
        }
    }

    function addFunds() payable public onlyOwner {
    }

    function scapeHatch() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    //GETS
    function getEmployeeCount() public view returns(uint256 employeeCount) {
        return employeeIndex.length;
    }

    function getEmployeeById(uint index) public view returns(address userAddress) {
        return employeeIndex[index];
    }

    function getEmployee(uint employeeId) public view returns(address employeeAddress, address[] allowedToken, uint256 salary) {
        Employee storage selectedEmployee = m_employees[getEmployeeById(employeeId)];

        employeeAddress = selectedEmployee.accountAddress;
        allowedToken = selectedEmployee.allowedToken;
        salary = selectedEmployee.yearlyEURSalary;
    }
    
    function addTokenFunds(address _spender, uint256 _value, bytes _extraData) public {
        //Calling from EURToken
        approveAndCall(_spender, _value, _extraData);
    }

    function calculatePayrollBurnrate() public view returns (uint256) {
        return updatedTotalYearlySalary / 12;
    }

    function calculatePayrollRunway() public view returns (uint256) {
        uint256 costPerDay = updatedTotalYearlySalary / 365;
        uint256 daysUntilDry = this.balance / costPerDay;

        return daysUntilDry;
    }

    //EMPLOYEE ONLY
    function determineAllocation(address[] tokens, uint256[] distribution) public onlyEmployee {
        require(tokens.length == distribution.length);

        Employee storage employee = m_employees[msg.sender];
        
        uint8 lastAllocation = getMonth(employee.lastDistributionDay);
        uint8 actualMonth = getMonth(now);
        uint8 monthDiff = lastAllocation - actualMonth;

        if (!(monthDiff >= 6)) {
            revert();
        } else {
            employee.allowedToken = tokens;
            employee.tokenDistribution = distribution;
            employee.lastDistributionDay = now;

            for (uint i = 0; i < tokens.length; i++) {
                if (!(tokenExist(tokens[i]))) {
                    insertToken(tokens[i], 0);
                }
            }
        }
    }

    function payday() public onlyEmployee {
        Employee storage employee = m_employees[msg.sender];

        uint8 lastPayMonth = getMonth(employee.lastPayCheck);
        uint8 actualMonth = getMonth(now);
        uint8 monthDiff = lastPayMonth - actualMonth;
        
        if (!(monthDiff >= 1)) {
            revert();
        } else {
            for (uint i = 0; i < employee.allowedToken.length; i++) {
                uint256 amountOfTokens = (employee.yearlyEURSalary / 12) / employee.tokenDistribution[i];
                if (m_token[employee.allowedToken[i]].EURExchangeRate != 0) {
                    uint256 payment = amountOfTokens * m_token[employee.allowedToken[i]].EURExchangeRate;

                    EURToken eurToken = EURToken(employee.allowedToken[i]);
                    eurToken.transfer(msg.sender, payment);
                }
            }
        }
    }


    //ORACLE ONLY
    function setExchangeRate(address token, uint256 exchangeRate) public onlyOracle {
        require(exchangeRate > 0);

        EURToken standardToken = EURToken(m_token[token].token);
        m_token[token].EURExchangeRate = exchangeRate * standardToken.decimals();
    }    

    function updateTotalSalary(uint256 salaryNow, uint256 salaryBefore) internal {
        updatedTotalYearlySalary += salaryNow - salaryBefore;
    }

    //VALIDATION
    function employeeExist(address newAddress) public view returns (bool addressExist) {
        if (employeeIndex.length == 0)
            return false;
        
        return (employeeIndex[m_employees[newAddress].employeedId] == newAddress);
    }

    function tokenExist(address newToken) public view returns (bool tokenAlreadyRegistered) {
        if (tokenIndex.length == 0)
            return false;
        
        return (tokenIndex[m_token[newToken].tokenId] == newToken);
    }
}