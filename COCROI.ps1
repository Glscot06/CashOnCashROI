Add-Type -AssemblyName PresentationFramework

# Define XAML UI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Cash on Cash ROI Calculator"
        Height="720" Width="450"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E2F">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Cash on Cash ROI Calculator"
                   FontSize="22" FontWeight="Bold"
                   Foreground="White" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <StackPanel Grid.Row="1" Orientation="Vertical" VerticalAlignment="Top" Margin="0,0,0,20">
            <StackPanel.Resources>
                <Style TargetType="TextBox">
                    <Setter Property="Margin" Value="0,5,0,10"/>
                    <Setter Property="Padding" Value="6"/>
                    <Setter Property="FontSize" Value="14"/>
                    <Setter Property="Background" Value="#2D2D44"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="BorderBrush" Value="#444"/>
                    <Setter Property="BorderThickness" Value="1"/>
                </Style>
                <Style TargetType="TextBlock">
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontSize" Value="14"/>
                    <Setter Property="Margin" Value="0,5,0,0"/>
                </Style>
            </StackPanel.Resources>

            <TextBlock Text="Purchase Price:"/>
            <TextBox Name="PurchasePrice"/>

            <TextBlock Text="Percent Down (%):"/>
            <TextBox Name="PercentDown"/>

            <TextBlock Text="Renovation Estimate:"/>
            <TextBox Name="RenovationCost"/>

            <TextBlock Text="Closing Costs (% of Purchase Price):"/>
            <TextBox Name="ClosingCosts"/>

            <TextBlock Text="Estimated Monthly Rent:"/>
            <TextBox Name="RentPerMonth"/>

            <TextBlock Text="Yearly Insurance:"/>
            <TextBox Name="YearlyInsurance"/>

            <TextBlock Text="Yearly Taxes:"/>
            <TextBox Name="YearlyTaxes"/>

            <TextBlock Text="Additional Income (annual):"/>
            <TextBox Name="AdditionalIncome"/>

            <TextBlock Text="Interest Rate (%):"/>
            <TextBox Name="InterestRate"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Orientation="Vertical" HorizontalAlignment="Center">
            <Button Content="Calculate" Width="150" Height="40"
                    Background="#4C8BF5" Foreground="White"
                    FontWeight="Bold" BorderThickness="0" Margin="0,10,0,10"
                    Cursor="Hand" Name="CalculateButton"/>

            <TextBlock Text="Results:" FontSize="16" FontWeight="Bold" Margin="0,10,0,0"/>
            <TextBlock Name="ResultsText" Text="" TextWrapping="Wrap" FontSize="14" Foreground="#B0E0E6" Margin="0,5,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$PurchasePrice   = $window.FindName("PurchasePrice")
$PercentDown     = $window.FindName("PercentDown")
$RenovationCost  = $window.FindName("RenovationCost")
$ClosingCosts    = $window.FindName("ClosingCosts")
$RentPerMonth    = $window.FindName("RentPerMonth")
$YearlyInsurance = $window.FindName("YearlyInsurance")
$YearlyTaxes     = $window.FindName("YearlyTaxes")
$AdditionalIncome= $window.FindName("AdditionalIncome")
$InterestRate    = $window.FindName("InterestRate")
$CalculateButton = $window.FindName("CalculateButton")
$ResultsText     = $window.FindName("ResultsText")

# Calculation logic
$CalculateButton.Add_Click({
    try {
        $purchasePrice   = [double]$PurchasePrice.Text
        $percentDown     = [double]$PercentDown.Text / 100
        $renovationCost  = [double]$RenovationCost.Text
        $closingCostPct  = [double]$ClosingCosts.Text / 100
        $rentPerMonth    = [double]$RentPerMonth.Text
        $yearlyInsurance = [double]$YearlyInsurance.Text
        $yearlyTaxes     = [double]$YearlyTaxes.Text
        $additionalIncome= [double]$AdditionalIncome.Text
        $interestRate    = [double]$InterestRate.Text / 100

        # Loan and investment calculations
        $downPayment     = $purchasePrice * $percentDown
        $closingCostsAmt = $purchasePrice * $closingCostPct
        $loanAmount      = $purchasePrice - $downPayment
        $monthlyInterest = $interestRate / 12
        $loanTermMonths  = 360 # 30 years

        $powValue = [math]::Pow((1 + $monthlyInterest), $loanTermMonths)
        $monthlyPayment  = $loanAmount * ($monthlyInterest * $powValue) / ($powValue - 1)

        # Cash invested includes down payment, renovation, closing costs
        $totalCashInvested = $downPayment + $renovationCost + $closingCostsAmt

        # Annual and monthly calculations
        $annualIncome = ($rentPerMonth * 12) + $additionalIncome
        $annualExpenses = ($monthlyPayment * 12) + $yearlyInsurance + $yearlyTaxes
        $annualCashFlow = $annualIncome - $annualExpenses

        # Monthly cash flow
        $monthlyCashFlow = ($rentPerMonth + ($additionalIncome / 12)) - ($monthlyPayment + (($yearlyInsurance + $yearlyTaxes) / 12))

        # Monthly mortgage including taxes & insurance
        $monthlyMortgageWithTI = $monthlyPayment + (($yearlyInsurance + $yearlyTaxes) / 12)

        # Cash on Cash ROI
        $cocROI = if ($totalCashInvested -ne 0) { ($annualCashFlow / $totalCashInvested) * 100 } else { 0 }

        # Display results
        $ResultsText.Text = "Total Cash Invested: $($totalCashInvested.ToString('C0'))`n" +
                            "Estimated Monthly Mortgage (incl. Taxes & Insurance): $($monthlyMortgageWithTI.ToString('C0'))`n" +
                            "Monthly Cash Flow: $($monthlyCashFlow.ToString('C0'))`n" +
                            "Annual Cash Flow: $($annualCashFlow.ToString('C0'))`n" +
                            "Cash on Cash ROI: $($cocROI.ToString('N2'))%"
    }
    catch {
        $ResultsText.Text = "⚠️ Please enter valid numeric values for all fields."
    }
})

# Show window
$window.ShowDialog() | Out-Null
