pragma solidity ^0.4.18;

// Project 
// Write the code (deployable to the EVM), publish it on GitHub (public or private) and send the link to the repo. Please include any additional information you consider important. 
// The code we are looking for could be conformant to the following interface. Feel free to remove/add any functions as you see fit: 
// For the sake of simplicity lets assume EUR is a ERC20 token 
// Also lets assume we can 100% trust the exchange rate oracle
 
interface PayrollInterface { 
/* OWNER ONLY */ 
    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary) public; 
    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary) public; 
    function removeEmployee(uint256 employeeId) public; 

    function addFunds() payable public; 
    function scapeHatch() public; 

    function addTokenFunds(address _spender, uint256 _value, bytes _extraData) public; // Use approveAndCall or ERC223 tokenFallback 
    function getEmployeeCount() public view returns (uint256); 
    function getEmployee(uint256 employeeId) public view returns (address employeeAddress, address[] allowedToken, uint256 salary); 
    function calculatePayrollBurnrate() public view returns (uint256); // Monthly EUR amount spent in salaries 
    function calculatePayrollRunway() public view returns (uint256); // Days until the contract can run out of funds

// /* EMPLOYEE ONLY */ 
    function determineAllocation(address[] tokens, uint256[] distribution) public; // only callable once every 6 months 
    function payday() public; // only callable once a month 

// /* ORACLE ONLY */ 
    function setExchangeRate(address token, uint256 EURExchangeRate) public; // uses decimals from token  
}