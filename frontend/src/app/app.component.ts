import { Component } from '@angular/core';
import { environment } from '../environments/environment';
import { DataService } from './data.service';
import { Todoitem } from './todoitem';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  todolist: Todoitem[] = [];
  title = 'frontend';

  constructor(private dataService: DataService) { }

  ngOnInit() {
    this.dataService.sendGetRequest().subscribe((data: Todoitem[])=>{
      console.log(data);
      this.todolist = data;
    })  
  }

}
