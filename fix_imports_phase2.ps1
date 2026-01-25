# Phase 2 Import Fixer
$ErrorActionPreference = "Continue"

$phase2 = @{
    "import '../utils/responsive_helper.dart'" = "import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart'"
    "import '../providers/registration_provider.dart'" = "import 'package:sehat_makaan_flutter/data/providers/registration_provider.dart'"
    "import '../../widgets/dashboard/dashboard_app_bar.dart'" = "import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/dashboard_app_bar.dart'"
    "import '../../widgets/dashboard/dashboard_sidebar.dart'" = "import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/dashboard_sidebar.dart'"
    "import '../../services/user_status_service.dart'" = "import 'package:sehat_makaan_flutter/features/auth/services/user_status_service.dart'"
    "import 'package:sehat_makaan_flutter/services/fcm_service.dart'" = "import 'package:sehat_makaan_flutter/shared/fcm_service.dart'"
    "import '../../features/bookings/widgets/live_slot_booking_widget.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/widgets/live_slot_booking_widget.dart'"
    "import '../../../../../screens/user/booking_workflow/suite_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/suite_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/booking_type_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/booking_type_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/package_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/package_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/specialty_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/specialty_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/date_slot_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/date_slot_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/addons_selection_step.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/addons_selection_step.dart'"
    "import '../../../../../screens/user/booking_workflow/booking_summary_widget.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/booking_summary_widget.dart'"
    "import '../../../../../screens/user/booking_workflow/payment_step.dart'" = "import 'package:sehat_makaan_flutter/features/payments/screens/payment_step.dart'"
    "import '../../../utils/types.dart'" = "import 'package:sehat_makaan_flutter/core/constants/types.dart'"
    "import '../utils/types.dart'" = "import 'package:sehat_makaan_flutter/core/constants/types.dart'"
    "import 'package:sehat_makaan_flutter/screens/user/booking_workflow/payfast_webview_screen.dart'" = "import 'package:sehat_makaan_flutter/features/payments/screens/payfast_webview_screen.dart'"
    "import 'package:sehat_makaan_flutter/utils/dashboard_utils.dart'" = "import 'package:sehat_makaan_flutter/core/utils/dashboard_utils.dart'"
}

Write-Host "Starting Phase 2 fixes..." -ForegroundColor Cyan
$fixed = 0

Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    
    foreach($oldImport in $phase2.Keys) {
        $newImport = $phase2[$oldImport]
        $escapedOld = [regex]::Escape($oldImport)
        if($content -match $escapedOld) {
            $content = $content -replace $escapedOld, $newImport
            $fixed++
        }
    }
    
    if($content -ne $original) {
        Set-Content $_.FullName $content -NoNewline
        Write-Host "Fixed: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "`nMade $fixed fixes in Phase 2" -ForegroundColor Yellow
