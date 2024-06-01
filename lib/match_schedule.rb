# frozen_string_literal: true

IPL_SCHEDULE = [
  { match_number: 1, match_day: 1, date: '22-Mar-2024', stadium: 'Chennai', match_name: 'CSK vs RCB' },
  { match_number: 2, match_day: 2, date: '23-Mar-2024', stadium: 'Mullanpur', match_name: 'PBKS vs DC' },
  { match_number: 3, match_day: 2, date: '23-Mar-2024', stadium: 'Kolkata', match_name: 'KKR vs SRH' },
  { match_number: 4, match_day: 3, date: '24-Mar-2024', stadium: 'Jaipur', match_name: 'RR vs LSG' },
  { match_number: 5, match_day: 3, date: '24-Mar-2024', stadium: 'Ahmedabad', match_name: 'GT vs MI' },
  { match_number: 6, match_day: 4, date: '25-Mar-2024', stadium: 'Bengaluru', match_name: 'RCB vs PBKS' },
  { match_number: 7, match_day: 5, date: '26-Mar-2024', stadium: 'Chennai', match_name: 'CSK vs GT' },
  { match_number: 8, match_day: 6, date: '27-Mar-2024', stadium: 'Hyderabad', match_name: 'SRH vs MI' },
  { match_number: 9, match_day: 7, date: '28-Mar-2024', stadium: 'Jaipur', match_name: 'RR vs DC' },
  { match_number: 10, match_day: 8, date: '29-Mar-2024', stadium: 'Bengaluru', match_name: 'RCB vs KKR' },
  { match_number: 11, match_day: 9, date: '30-Mar-2024', stadium: 'Lucknow', match_name: 'LSG vs PBKS' },
  { match_number: 12, match_day: 10, date: '31-Mar-2024', stadium: 'Ahmedabad', match_name: 'GT vs SRH' },
  { match_number: 13, match_day: 10, date: '31-Mar-2024', stadium: 'Visakhapatnam', match_name: 'DC vs CSK' },
  { match_number: 14, match_day: 11, date: '01-Apr-2024', stadium: 'Mumbai', match_name: 'MI vs RR' },
  { match_number: 15, match_day: 12, date: '02-Apr-2024', stadium: 'Bengaluru', match_name: 'RCB vs LSG' },
  { match_number: 16, match_day: 13, date: '03-Apr-2024', stadium: 'Visakhapatnam', match_name: 'DC vs KKR' },
  { match_number: 17, match_day: 14, date: '04-Apr-2024', stadium: 'Ahmedabad', match_name: 'GT vs PBKS' },
  { match_number: 18, match_day: 15, date: '05-Apr-2024', stadium: 'Hyderabad', match_name: 'SRH vs CSK' },
  { match_number: 19, match_day: 16, date: '06-Apr-2024', stadium: 'Jaipur', match_name: 'RR vs RCB' },
  { match_number: 20, match_day: 17, date: '07-Apr-2024', stadium: 'Mumbai', match_name: 'MI vs DC' },
  { match_number: 21, match_day: 17, date: '07-Apr-2024', stadium: 'Lucknow', match_name: 'LSG vs GT' },
  { match_number: 22, match_day: 18, date: '08-Apr-2024', stadium: 'Chennai', match_name: 'CSK vs KKR' },
  { match_number: 23, match_day: 19, date: '09-Apr-2024', stadium: 'Mullanpur', match_name: 'PBKS vs SRH' },
  { match_number: 24, match_day: 20, date: '10-Apr-2024', stadium: 'Jaipur', match_name: 'RR vs GT' },
  { match_number: 25, match_day: 21, date: '11-Apr-2024', stadium: 'Mumbai', match_name: 'MI vs PBKS' },
  { match_number: 26, match_day: 22, date: '12-Apr-2024', stadium: 'Lucknow', match_name: 'LSG vs DC' },
  { match_number: 27, match_day: 23, date: '13-Apr-2024', stadium: 'Mullanpur', match_name: 'PBKS vs RR' },
  { match_number: 28, match_day: 24, date: '14-Apr-2024', stadium: 'Kolkata', match_name: 'KKR vs LSG' },
  { match_number: 29, match_day: 24, date: '14-Apr-2024', stadium: 'Mumbai', match_name: 'MI vs CSK' },
  { match_number: 30, match_day: 25, date: '15-Apr-2024', stadium: 'Bengaluru', match_name: 'RCB vs SRH' },
  { match_number: 31, match_day: 26, date: '16-Apr-2024', stadium: 'Ahmedabad', match_name: 'GT vs DC' },
  { match_number: 32, match_day: 27, date: '17-Apr-2024', stadium: 'Kolkata', match_name: 'KKR vs RR' },
  { match_number: 33, match_day: 28, date: '18-Apr-2024', stadium: 'Mullanpur', match_name: 'PBKS vs MI' },
  { match_number: 34, match_day: 29, date: '19-Apr-2024', stadium: 'Lucknow', match_name: 'LSG vs CSK' },
  { match_number: 35, match_day: 30, date: '20-Apr-2024', stadium: 'Delhi', match_name: 'DC vs PBKS' },
  { match_number: 36, match_day: 31, date: '21-Apr-2024', stadium: 'Kolkata', match_name: 'KKR vs RCB' },
  { match_number: 37, match_day: 31, date: '21-Apr-2024', stadium: 'Mullanpur', match_name: 'PBKS vs GT' },
  { match_number: 38, match_day: 32, date: '22-Apr-2024', stadium: 'Jaipur', match_name: 'RR vs MI' },
  { match_number: 39, match_day: 33, date: '23-Apr-2024', stadium: 'Chennai', match_name: 'CSK vs LSG' },
  { match_number: 40, match_day: 34, date: '24-Apr-2024', stadium: 'Delhi', match_name: 'DC vs GT' },
  { match_number: 41, match_day: 35, date: '25-Apr-2024', stadium: 'Hyderabad', match_name: 'SRH vs RCB' },
  { match_number: 42, match_day: 36, date: '26-Apr-2024', stadium: 'Kolkata', match_name: 'KKR vs PBKS' },
  { match_number: 43, match_day: 37, date: '27-Apr-2024', stadium: 'Delhi', match_name: 'DC vs MI' },
  { match_number: 44, match_day: 37, date: '27-Apr-2024', stadium: 'Lucknow', match_name: 'LSG vs RR' },
  { match_number: 45, match_day: 38, date: '28-Apr-2024', stadium: 'Ahmedabad', match_name: 'GT vs RCB' },
  { match_number: 46, match_day: 38, date: '28-Apr-2024', stadium: 'Chennai', match_name: 'CSK vs SRH' },
  { match_number: 47, match_day: 39, date: '29-Apr-2024', stadium: 'Kolkata', match_name: 'KKR vs DC' },
  { match_number: 48, match_day: 40, date: '30-Apr-2024', stadium: 'Lucknow', match_name: 'LSG vs MI' },
  { match_number: 49, match_day: 41, date: '01-May-2024', stadium: 'Chennai', match_name: 'CSK vs PBKS' },
  { match_number: 50, match_day: 42, date: '02-May-2024', stadium: 'Hyderabad', match_name: 'SRH vs RR' },
  { match_number: 51, match_day: 43, date: '03-May-2024', stadium: 'Mumbai', match_name: 'MI vs KKR' },
  { match_number: 52, match_day: 44, date: '04-May-2024', stadium: 'Bengaluru', match_name: 'RCB vs GT' },
  { match_number: 53, match_day: 45, date: '05-May-2024', stadium: 'Dharamshala', match_name: 'PBKS vs CSK' },
  { match_number: 54, match_day: 45, date: '05-May-2024', stadium: 'Lucknow', match_name: 'LSG vs KKR' },
  { match_number: 55, match_day: 46, date: '06-May-2024', stadium: 'Mumbai', match_name: 'MI vs SRH' },
  { match_number: 56, match_day: 47, date: '07-May-2024', stadium: 'Delhi', match_name: 'DC vs RR' },
  { match_number: 57, match_day: 48, date: '08-May-2024', stadium: 'Hyderabad', match_name: 'SRH vs LSG' },
  { match_number: 58, match_day: 49, date: '09-May-2024', stadium: 'Dharamshala', match_name: 'PBKS vs RCB' },
  { match_number: 59, match_day: 50, date: '10-May-2024', stadium: 'Ahmedabad', match_name: 'GT vs CSK' },
  { match_number: 60, match_day: 51, date: '11-May-2024', stadium: 'Kolkata', match_name: 'KKR vs MI' },
  { match_number: 61, match_day: 52, date: '12-May-2024', stadium: 'Chennai', match_name: 'CSK vs RR' },
  { match_number: 62, match_day: 52, date: '12-May-2024', stadium: 'Bengaluru', match_name: 'RCB vs DC' },
  { match_number: 63, match_day: 53, date: '13-May-2024', stadium: 'Ahmedabad', match_name: 'GT vs KKR' },
  { match_number: 64, match_day: 54, date: '14-May-2024', stadium: 'Delhi', match_name: 'DC vs LSG' },
  { match_number: 65, match_day: 55, date: '15-May-2024', stadium: 'Guwaha�', match_name: 'RR vs PBKS' },
  { match_number: 66, match_day: 56, date: '16-May-2024', stadium: 'Hyderabad', match_name: 'SRH vs GT' },
  { match_number: 67, match_day: 57, date: '17-May-2024', stadium: 'Mumbai', match_name: 'MI vs LSG' },
  { match_number: 68, match_day: 58, date: '18-May-2024', stadium: 'Bengaluru', match_name: 'RCB vs CSK' },
  { match_number: 69, match_day: 59, date: '19-May-2024', stadium: 'Hyderabad', match_name: 'SRH vs PBKS' },
  { match_number: 70, match_day: 59, date: '19-May-2024', stadium: 'Guwaha�', match_name: 'RR vs KKR' }
].freeze

T20_WORLDCUP_SCHEDULE = [
  { match_number: 1, match_name: 'USA vs Canada', stadium: 'Dallas', match_date: '02-June-2024',
    time: '6 AM' },
  { match_number: 2, match_name: 'West Indies vs Papua New Guinea', stadium: 'Guyana',
    match_date: '02-June-2024', time: '8 PM' },
  { match_number: 3, match_name: 'Namibia vs Oman', stadium: 'Barbados', match_date: '03-June-2024',
    time: '6 AM' },
  { match_number: 4, match_name: 'Sri Lanka vs South Africa', stadium: 'New York', match_date: '03-June-2024',
    time: '8 PM' },
  { match_number: 5, match_name: 'Afghanistan vs Uganda', stadium: 'Guyana', match_date: '04-June-2024',
    time: '6 AM' },
  { match_number: 6, match_name: 'England vs Scotland', stadium: 'Barbados', match_date: '04-June-2024',
    time: '8 PM' },
  { match_number: 7, match_name: 'Netherlands vs Nepal', stadium: 'Dallas', match_date: '04-June-2024',
    time: '9 PM' },
  { match_number: 8, match_name: 'India vs Ireland', stadium: 'New York', match_date: '05-June-2024',
    time: '8 PM' },
  { match_number: 9, match_name: 'Papua New Guinea vs Uganda', stadium: 'Guyana', match_date: '06-June-2024',
    time: '5 AM' },
  { match_number: 10, match_name: 'Australia vs Oman', stadium: 'Barbados', match_date: '06-June-2024',
    time: '6 AM' },
  { match_number: 11, match_name: 'USA vs Pakistan', stadium: 'Dallas', match_date: '06-June-2024',
    time: '9 PM' },
  { match_number: 12, match_name: 'Namibia vs Scotland', stadium: 'Barbados', match_date: '07-June-2024',
    time: '12:30 AM' },
  { match_number: 13, match_name: 'Canada vs Ireland', stadium: 'New York', match_date: '07-June-2024',
    time: '8 PM' },
  { match_number: 14, match_name: 'New Zealand vs Afghanistan', stadium: 'Guyana', match_date: '08-June-2024',
    time: '5 AM' },
  { match_number: 15, match_name: 'Sri Lanka vs Bangladesh', stadium: 'Dallas', match_date: '08-June-2024',
    time: '6 AM' },
  { match_number: 16, match_name: 'Netherlands vs South Africa', stadium: 'New York',
    match_date: '08-June-2024', time: '8 PM' },
  { match_number: 17, match_name: 'Australia vs England', stadium: 'Barbados', match_date: '08-June-2024',
    time: '10:30 PM' },
  { match_number: 18, match_name: 'West Indies vs Uganda', stadium: 'Guyana', match_date: '09-June-2024',
    time: '6 AM' },
  { match_number: 19, match_name: 'India vs Pakistan', stadium: 'New York', match_date: '09-June-2024',
    time: '8 PM' },
  { match_number: 20, match_name: 'Oman vs Scotland', stadium: 'Antigua', match_date: '09-June-2024',
    time: '10:30 PM' },
  { match_number: 21, match_name: 'South Africa vs Bangladesh', stadium: 'New York',
    match_date: '10-June-2024', time: '8 PM' },
  { match_number: 22, match_name: 'Pakistan vs Canada', stadium: 'New York', match_date: '11-June-2024',
    time: '8 PM' },
  { match_number: 23, match_name: 'Sri Lanka vs Nepal', stadium: 'Florida', match_date: '12-June-2024',
    time: '5 AM' },
  { match_number: 24, match_name: 'Australia vs Namibia', stadium: 'Antigua', match_date: '12-June-2024',
    time: '6 AM' },
  { match_number: 25, match_name: 'USA vs India', stadium: 'New York', match_date: '12-June-2024',
    time: '8 PM' },
  { match_number: 26, match_name: 'West Indies vs New Zealand', stadium: 'Trinidad & Tobago',
    match_date: '13-June-2024', time: '6 AM' },
  { match_number: 27, match_name: 'Bangladesh vs Netherlands', stadium: 'St Vincent',
    match_date: '13-June-2024', time: '8 PM' },
  { match_number: 28, match_name: 'England vs Oman', stadium: 'Antigua', match_date: '14-June-2024',
    time: '12:30 AM' },
  { match_number: 29, match_name: 'Afghanistan vs Papua New Guinea', stadium: 'Trinidad & Tobago',
    match_date: '14-June-2024', time: '6 AM' },
  { match_number: 30, match_name: 'USA vs Ireland', stadium: 'Florida', match_date: '14-June-2024',
    time: '8 PM' },
  { match_number: 31, match_name: 'South Africa vs Nepal', stadium: 'St Vincent', match_date: '15-June-2024',
    time: '5 AM' },
  { match_number: 32, match_name: 'New Zealand vs Uganda', stadium: 'Trinidad & Tobago',
    match_date: '15-June-2024', time: '6 AM' },
  { match_number: 33, match_name: 'India vs Canada', stadium: 'Florida', match_date: '15-June-2024',
    time: '8 PM' },
  { match_number: 34, match_name: 'Namibia vs England', stadium: 'Antigua', match_date: '15-June-2024',
    time: '10:30 PM' },
  { match_number: 35, match_name: 'Australia vs Scotland', stadium: 'St Lucia', match_date: '16-June-2024',
    time: '6 AM' },
  { match_number: 36, match_name: 'Pakistan vs Ireland', stadium: 'Florida', match_date: '16-June-2024',
    time: '8 PM' },
  { match_number: 37, match_name: 'Bangladesh vs Nepal', stadium: 'St Vincent', match_date: '17-June-2024',
    time: '5 AM' },
  { match_number: 38, match_name: 'Sri Lanka vs Netherlands', stadium: 'St Lucia', match_date: '17-June-2024',
    time: '6 AM' },
  { match_number: 39, match_name: 'New Zealand vs Papua New Guinea', stadium: 'Trinidad & Tobago',
    match_date: '17-June-2024', time: '8 PM' },
  { match_number: 40, match_name: 'West Indies vs Afghanistan', stadium: 'St Lucia',
    match_date: '18-June-2024', time: '6 AM' },
  { match_number: 41, match_name: 'A2 vs D1', stadium: 'Antigua', match_date: '19-June-2024', time: '8 PM' },
  { match_number: 42, match_name: 'B1 vs C2', stadium: 'St Lucia', match_date: '20-June-2024', time: '6 AM' },
  { match_number: 43, match_name: 'C1 vs A1', stadium: 'Barbados', match_date: '20-June-2024', time: '8 PM' },
  { match_number: 44, match_name: 'B2 vs D2', stadium: 'Antigua', match_date: '21-June-2024', time: '6 AM' },
  { match_number: 45, match_name: 'B1 vs D1', stadium: 'St Lucia', match_date: '21-June-2024', time: '8 PM' },
  { match_number: 46, match_name: 'A2 vs C2', stadium: 'Barbados', match_date: '22-June-2024', time: '6 AM' },
  { match_number: 47, match_name: 'A1 vs D2', stadium: 'Antigua', match_date: '22-June-2024', time: '8 PM' },
  { match_number: 48, match_name: 'C1 vs B2', stadium: 'St Vincent', match_date: '23-June-2024',
    time: '6 AM' },
  { match_number: 49, match_name: 'A2 vs B1', stadium: 'Barbados', match_date: '23-June-2024', time: '8 PM' },
  { match_number: 50, match_name: 'C2 vs D1', stadium: 'Antigua', match_date: '24-June-2024', time: '6 AM' },
  { match_number: 51, match_name: 'B2 vs A1', stadium: 'St Lucia', match_date: '24-June-2024', time: '8 PM' },
  { match_number: 52, match_name: 'C1 vs D2', stadium: 'St Vincent', match_date: '25-June-2024',
    time: '6 AM' },
  { match_number: 53, match_name: '1st Semi-Final', stadium: 'Trinidad & Tobago', match_date: '27-June-2024',
    time: '6 AM' },
  { match_number: 54, match_name: '2nd Semi-Final', stadium: 'Guyana', match_date: '27-June-2024',
    time: '8 PM' },
  { match_number: 55, match_name: 'Final', stadium: 'Barbados', match_date: '29-June-2024', time: '8 PM' }
].freeze
