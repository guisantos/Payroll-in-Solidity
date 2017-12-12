pragma solidity ^0.4.18;

import "./PayrollInterface.sol";
import "./Owned.sol";
import "./date/Datetime.sol";
import "./Token/EURToken.sol";

contract Payroll is EURToken, PayrollInterface, Owned, Datetime {

    //EVENTS
    event NewEmployee(uint256 employeeId, address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary);
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
        address token;
        uint256 EURExchangeRate;
    }

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
        insertToken(address(0x123), 0);
        oracle = _oracle;
    }

    //FUNCTIONS
    function insertToken(address newTokenAddress, uint256 EURExchangeRate) internal {
        require(newTokenAddress != address(0) && EURExchangeRate >= 0);

        var newToken = Token(newTokenAddress, EURExchangeRate);
        m_token[newTokenAddress] = newToken;
    }

    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary) onlyOwner public {
        require(accountAddress != address(0) && allowedTokens.length > 0 && initialYearlyEURSalary > 0);

        if (!employeeExist(accountAddress)) {
            var newEmployee = Employee(employeeIndex.length, accountAddress, allowedTokens, initialYearlyEURSalary, now, now);

            NewEmployee(employeeIndex.length, accountAddress, allowedTokens, initialYearlyEURSalary);
            m_employees[accountAddress] = newEmployee;

            updateTotalSalary(initialYearlyEURSalary, 0);
            employeeIndex.push(accountAddress);
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

    function employeeExist(address newAddress) public view returns (bool addressExist) {
        if (employeeIndex.length == 0)
            return false;
        
        return (employeeIndex[m_employees[newAddress].employeedId] == newAddress);
    }

    
    function addTokenFunds(address _spender, uint256 _value, bytes _extraData) public {
        //Calling from EURToken
        approveAndCall(_spender, _value, _extraData);
    }

    function calculatePayrollBurnrate() public view returns (uint256) {
        return updatedTotalYearlySalary / 12;
    }

    function determineAllocation(address[] tokens, uint256[] distribution) public onlyEmployee {
        Employee storage employee = m_employees[msg.sender];
        
        //#TODO: IMPLEMENT 6 MONTH CHECK
        
        //must be the same length
         require(tokens.length == distribution.length);

        //Employee can add new tokens as well
        employee.tokens = tokens;
        employee.distribution = distribution;
        employee.lastDistributionDay = now;
    }

    function payday() public onlyEmployee {
        Employee storage employee = m_employees[msg.sender];

        //#TODO: IMPLEMENT 1 MONTH CHECK

    }

    function setExchangeRate(address token, uint256 exchangeRate) public onlyOracle {
        require(exchangeRate > 0);

        EURToken standardToken = EURToken(m_token[token].token);
        m_token[token].EURExchangeRate = exchangeRate * standardToken.decimals();
    }    

    function addFunds() payable public onlyOwner {
    }

    function scapeHatch() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    function updateTotalSalary(uint256 salaryNow, uint256 salaryBefore) internal {
        updatedTotalYearlySalary += salaryNow - salaryBefore;
    }
}